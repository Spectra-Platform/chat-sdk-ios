# Spectra Chat SDK for iOS

Swift Package 기반의 Spectra Platform Chat iOS SDK다. 첫 slice는 AuthSDK에서 받은 app-user token provider를 주입받아 Chat API를 호출하고, WebSocket 연결에 필요한 authenticated request와 command envelope 경계를 제공한다.

## 현재 구현 상태

- Swift Package: `SpectraChatSDK`
- Package URL: `https://github.com/Spectra-Platform/chat-sdk-ios.git`
- Public configuration: `baseURL`, `projectId`
- Public token provider: `SpectraChatAccessTokenProviding`
- REST API:
  - `GET /v1/chat/rooms`
  - `POST /v1/chat/rooms/direct`
  - `POST /v1/chat/rooms/group`
  - `POST /v1/chat/rooms/{room_id}/messages`
  - `GET /v1/chat/rooms/{room_id}/messages`
  - `PUT /v1/chat/rooms/{room_id}/read-cursor` (`markRead` convenience 포함)
  - `POST /v1/chat/rooms/{room_id}/media/read-urls`
- Socket helper:
  - authenticated `/v1/socket` request
  - `message.send` command envelope
  - `read_cursor.update` command envelope
  - `/v1/socket` URL derivation
- Attachment boundary:
  - Storage SDK 직접 의존 없이 `SpectraChatStorageObjectReference`를 메시지 content에 첨부 가능

ChatSDK는 Notification push를 직접 발송하지 않는다. 메시지 저장 후 push 요청은 Chat 서버의 durable outbox와 Notification/Delivery consumer가 담당한다.

## 설치

```text
https://github.com/Spectra-Platform/chat-sdk-ios.git
```

개발 중에는 `main` branch를 사용할 수 있다.

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    branch: "main"
)
```

릴리즈 후에는 SemVer tag를 사용한다.

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    .upToNextMinor(from: "0.1.0")
)
```

target dependency:

```swift
.product(name: "SpectraChatSDK", package: "chat-sdk-ios")
```

## 사용 예시

```swift
import SpectraAuthSDK
import SpectraChatSDK

struct ChatTokenProvider: SpectraChatAccessTokenProviding {
    let auth: any TokenProvider

    func accessToken() async throws -> String {
        try await auth.getAccessToken().value
    }
}

let chat = SpectraChatClient(
    configuration: SpectraChatClientConfiguration(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        projectId: "project_123"
    ),
    tokenProvider: ChatTokenProvider(auth: authClient)
)

let rooms = try await chat.listRooms()
let messages = try await chat.listMessages(roomID: rooms[0].roomID)

let sent = try await chat.sendMessage(
    roomID: rooms[0].roomID,
    content: SpectraChatSendContent(kind: "text", text: "hello"),
    idempotencyKey: UUID().uuidString
)
```

WebSocket transport는 앱이 소유한다. SDK는 현재 서버 계약에 맞는 command envelope를 만든다.

```swift
let request = try await chat.socketRequest()
let command = chat.makeTextMessageCommand(
    roomID: "room_123",
    text: "hello"
)
```

## 로컬 검증

```bash
swift package describe
swift test
```

## 현재 미완료 경계

- URLSessionWebSocketTask 기반 reconnect/runtime transport
- message.created/read_cursor.updated/typing.updated/call event decoding convenience
- rich media upload는 Storage SDK upload 후 `SpectraChatStorageObjectReference` 전달 흐름으로 앱에서 연결 필요
- 실제 Spectra iOS 앱 integration
- 실제 message send → Chat outbox → Notification push 기기 수신 E2E
