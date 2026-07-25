# iOS ChatSDK Integration Guide

이 문서는 iOS 앱에서 `SpectraChatSDK`를 Swift Package로 붙이고, AuthSDK token provider를 통해 Chat REST API, authenticated WebSocket request와 command envelope를 사용하는 현재 기준을 설명한다.

## 1. Package 추가

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    branch: "main"
)
```

## 2. AuthSDK token provider adapter

```swift
import SpectraAuthSDK
import SpectraChatSDK

struct ChatTokenProvider: SpectraChatAccessTokenProviding {
    let auth: any TokenProvider

    func accessToken() async throws -> String {
        try await auth.getAccessToken().value
    }
}
```

## 3. Client 생성

```swift
let chat = SpectraChatClient(
    configuration: SpectraChatClientConfiguration(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        projectId: "project_123"
    ),
    tokenProvider: ChatTokenProvider(auth: authClient)
)
```

## 4. REST history와 room

```swift
let rooms = try await chat.listRooms(limit: 50)
let messages = try await chat.listMessages(roomID: rooms[0].roomID)

let sent = try await chat.sendMessage(
    roomID: rooms[0].roomID,
    content: SpectraChatSendContent(kind: "text", text: "hello"),
    idempotencyKey: UUID().uuidString
)

try await chat.markRead(
    roomID: rooms[0].roomID,
    lastReadServerSequence: sent.serverSequence
)
```

## 5. Storage attachment boundary

ChatSDK는 StorageSDK에 직접 의존하지 않는다. 앱은 StorageSDK로 업로드를 완료한 뒤 object reference만 Chat message content에 넘긴다.

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

SDK는 WebSocket transport를 직접 소유한다. 앱은 `SpectraChatRealtimeClient`를 만들고 event stream을 구독한다.

```swift
let realtime = SpectraChatRealtimeClient(client: chat)
let events = await realtime.events()

try await realtime.connect()

let message = try await realtime.sendTextMessage(
    roomID: "room_123",
    text: "hello",
    clientMessageID: UUID().uuidString
)

for await event in events {
    switch event {
    case .messageCreated(let message):
        print(message.messageID)
    case .readCursorUpdated(let cursor):
        print(cursor.lastReadServerSequence)
    case .typingUpdated(let typing):
        print(typing.isTyping)
    case .callLifecycle(let call):
        print(call.eventType.rawValue)
    default:
        break
    }
}
```

`SpectraChatRealtimeClient`는 authenticated `/v1/socket` request, `URLSessionWebSocketTask`, receive loop, command 송신과 기본 reconnect 상태 이벤트를 소유한다.

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
- rich media upload와 Media/Storage SDK 연결
- 실제 Spectra iOS app integration
- 실제 message send → push 수신 E2E
