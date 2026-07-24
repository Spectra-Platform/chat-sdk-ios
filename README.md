# Spectra Chat SDK for iOS

Swift Package 기반의 Spectra Chat iOS SDK다. 첫 slice는 기존 Chat REST 계약을 안전하게 감싸고, WebSocket `message.send` 명령 envelope를 생성하는 경계를 제공한다.

## 현재 구현 상태

- Swift Package: `SpectraChatSDK`
- Package URL: `https://github.com/Spectra-Platform/chat-sdk-ios.git`
- Public token provider: `SpectraChatAccessTokenProviding`
- REST API:
  - `GET /v1/chat/rooms`
  - `POST /v1/chat/rooms/direct`
  - `POST /v1/chat/rooms/group`
  - `GET /v1/chat/rooms/{room_id}/messages`
  - `PUT /v1/chat/rooms/{room_id}/read-cursor`
  - `POST /v1/chat/rooms/{room_id}/media/read-urls`
- Socket helper:
  - `message.send` command envelope
  - `read_cursor.update` command envelope
  - `/v1/socket` URL derivation

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
        baseURL: URL(string: "https://chat.spectra.kr")!
    ),
    tokenProvider: ChatTokenProvider(auth: authClient)
)

let rooms = try await chat.listRooms()
let messages = try await chat.listMessages(roomID: rooms[0].roomID)
```

WebSocket transport는 앱이 소유한다. SDK는 현재 서버 계약에 맞는 command envelope를 만든다.

```swift
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
- rich media upload는 Media/Storage SDK 흐름과 연결 필요
- 실제 Spectra iOS 앱 integration
- 실제 message send → Chat outbox → Notification push 기기 수신 E2E
