# iOS ChatSDK Integration Guide

이 문서는 iOS 앱에서 `SpectraChatSDK`를 Swift Package로 붙이고, AuthSDK token provider를 통해 Chat REST API와 WebSocket command envelope를 사용하는 현재 기준을 설명한다.

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
        baseURL: URL(string: "https://chat.spectra.kr")!
    ),
    tokenProvider: ChatTokenProvider(auth: authClient)
)
```

## 4. REST history와 room

```swift
let rooms = try await chat.listRooms(limit: 50)
let messages = try await chat.listMessages(roomID: rooms[0].roomID)

try await chat.updateReadCursor(
    roomID: rooms[0].roomID,
    lastReadServerSequence: messages.last?.serverSequence ?? 0
)
```

## 5. WebSocket command envelope

현재 SDK는 WebSocket transport를 직접 소유하지 않고, 서버 계약에 맞는 command envelope를 생성한다.

```swift
let socketURL = try chat.socketURL()
let command = chat.makeTextMessageCommand(
    roomID: "room_123",
    text: "hello",
    clientMessageID: UUID().uuidString
)
```

앱은 기존 WebSocket runtime 또는 후속 SDK transport slice로 `command`를 encode해 `/v1/socket`에 전송한다.

## 6. Push notification 경계

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

- WebSocket reconnect/runtime transport
- server event typed decoder convenience
- rich media upload와 Media/Storage SDK 연결
- 실제 Spectra iOS app integration
- 실제 message send → push 수신 E2E
