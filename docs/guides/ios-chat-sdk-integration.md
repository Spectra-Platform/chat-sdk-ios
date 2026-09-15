# iOS ChatSDK Integration Guide

이 문서는 iOS 앱에서 `SpectraChatSDK`를 Swift Package로 붙이고, AuthSDK 객체를 주입해 Chat REST API와 SDK-owned WebSocket realtime layer를 사용하는 현재 기준을 설명한다.

## 1. Package 추가

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    branch: "main"
)
```

## 2. AuthSDK 주입

```swift
import SpectraAuthSDK
import SpectraChatSDK

let auth = SpectraAuthClient(...)
```

## 3. Client 생성

```swift
let chat = SpectraChatClient(
    auth: auth,
    configuration: SpectraChatClientConfiguration(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        socketURL: URL(string: "wss://chat.spectra.kr/v1/socket")!,
        projectId: "project_123"
    )
)
```

기존 `SpectraChatAccessTokenProviding` 기반 초기화도 compatibility로 유지한다.

## 4. REST history와 room

```swift
let room = try await chat.createDirectRoom(userID: targetUserID)
let messages = try await chat.listMessages(roomID: room.id)

let sent = try await chat.sendMessage(
    roomID: room.id,
    text: "hello",
    idempotencyKey: UUID().uuidString
)

try await chat.markRead(
    roomID: room.id,
    sequence: sent.serverSequence
)
```

## 5. Storage attachment boundary

ChatSDK는 StorageSDK를 사용한 file helper도 제공한다. 이미 업로드된 object reference를 직접 넘기는 기존 경계도 유지한다.

```swift
let imageMessage = try await chat.sendMessage(
    roomID: "room_123",
    content: SpectraChatSendContent(
        kind: "media",
        text: "사진 보냈어",
        storageObjectReferences: [
            SpectraChatStorageObjectReference(
                objectKey: "/chat/room_123/image.png",
                contentType: "image/png"
            )
        ]
    ),
    idempotencyKey: UUID().uuidString
)
```

## 6. WebSocket realtime runtime

SDK는 WebSocket transport를 직접 소유한다. 앱은 raw WebSocket, reconnect, token refresh, room event filtering을 직접 구현하지 않는다.

```swift
chat.delegate = self
chat.logger = { level, event, fields in
    print("[spectra-chat]", level, event, fields)
}
try await chat.connect()
try await chat.subscribe(roomID: room.id)

let message = try await chat.sendMessage(
    roomID: room.id,
    text: "hello",
    clientMessageID: UUID().uuidString
)
```

`SpectraChatClient` 내부 realtime layer는 room websocket-ticket 발급, `/v1/socket?ticket=...`, `URLSessionWebSocketTask`, receive loop, command 송신과 기본 reconnect 상태 이벤트를 소유한다. token/ticket 원문은 logger fields에 넣지 않는다.

## 7. Push notification 경계

ChatSDK가 push를 직접 발송하지 않는다.

```text
Chat message transaction
→ chat.message-notification.requested.v1 outbox
→ Notification/Delivery consumer
→ APNs/FCM
→ 앱 NotificationSDK device registration과 push deep link 처리
```

앱은 foreground에서 이미 열린 conversation의 동일 message id에 대해 banner/sound를 억제하고, background push는 NotificationSDK와 시스템 알림 경로로 처리한다.

## 아직 완료가 아닌 것

- 실제 앱에서 기존 WebSocket adapter를 `SpectraChatRealtimeClient`로 교체
- 실제 네트워크 reconnect/backoff UX 세부 조율
- 실제 앱의 rich media upload UI와 Storage SDK 연결
- 실제 Spectra iOS app integration
- 실제 message send → push 수신 E2E
