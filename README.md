# Spectra Chat SDK for iOS

Swift Package 기반의 Spectra Platform Chat iOS SDK다. AuthSDK에서 받은 app-user token provider를 주입받아 Chat REST API와 WebSocket realtime runtime을 사용할 수 있게 한다.

## 현재 구현 상태

- Swift Package: `SpectraChatSDK`
- Package URL: `https://github.com/Spectra-Platform/chat-sdk-ios.git`
- Public configuration: SDK-owned production `baseURL`/`socketURL`, `projectId`
- Public token provider: `SpectraChatAccessTokenProviding`
- REST API:
  - `GET /v1/chat/rooms`
  - `POST /v1/chat/rooms/direct`
  - `POST /v1/chat/rooms/group`
  - `POST /v1/chat/rooms/{room_id}/leave`
  - `GET /v1/chat/rooms/{room_id}/membership`
  - `POST /v1/chat/rooms/{room_id}/messages`
  - `GET /v1/chat/rooms/{room_id}/messages`
  - `PUT /v1/chat/rooms/{room_id}/read-cursor` (`markRead` convenience 포함)
  - `POST /v1/chat/rooms/{room_id}/media/read-urls`
- Realtime WebSocket:
  - `SpectraChatRealtimeClient`
  - authenticated `/v1/socket` request 생성과 `URLSessionWebSocketTask` 연결
  - `connect()` / `disconnect()`
  - `events()` `AsyncStream<SpectraChatRealtimeEvent>`
  - `eventStream()` `AsyncStream<SpectraChatEvent>` JS parity stream
  - `message.send`, `typing.set`, `read_cursor.update` command 송신
  - `message.created`, `read_cursor.updated`, `typing.updated`, `room.membership.updated`, server error decode
  - `call.invited`/`call.state_updated`/`call.accepted`/`call.declined`/`call.joined`/`call.left`/`call.ended`/`call.missed` lifecycle event decoding
  - 기본 reconnect 상태 이벤트
- Attachment boundary:
  - `SpectraChatStorageObjectReference`를 메시지 content에 첨부 가능
  - StorageSDK를 사용해 이미지/파일/음성 업로드 후 메시지를 보내는
    `SpectraChatStorageAttachmentSender` 제공
  - JS `0.2.0` parity naming인 `uploadFiles(roomID:options:)`,
    `sendMessageWithFiles(roomID:options:)` 제공
- Offline/local state support:
  - `SpectraChatMessagePaginator`
  - `SpectraChatInMemoryStore`
  - `SpectraChatOfflineSendQueue`

ChatSDK는 Notification push를 직접 발송하지 않는다. 메시지 저장 후 push 요청은 Chat 서버의 durable outbox와 Notification/Delivery consumer가 담당한다.
ChatSDK의 call lifecycle decoder는 CallKit 또는 LiveKit token을 직접 다루지 않는다. Chat socket payload에는 통화 상태 참조만 있고, WebRTC SDP/ICE, LiveKit participant token, TURN credential과 provider secret은 Call API/CallSDK에서 받아야 한다. Decoder는 기존 flattened event와 Community Chat socket envelope(`payload.call`, `payload.change_type`, `payload.actor_user_id`)를 모두 지원한다.

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

ChatSDK의 첨부 helper는 StorageSDK를 함께 사용한다. 앱 target에
`SpectraStorageSDK`도 연결되어 있어야 한다.

## 사용 예시

Modo Camp의 JS SDK parity 목표와 membership/attachment Swift API 초안은
[Modo Camp iOS Chat SDK parity draft](docs/guides/modo-camp-ios-chat-parity.md)에
별도로 정리한다.

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
    projectId: "project_123",
    tokenProvider: ChatTokenProvider(auth: authClient)
)

let rooms = try await chat.listRooms()
let messages = try await chat.listMessages(roomID: rooms[0].roomID)

let sent = try await chat.sendMessage(
    roomID: rooms[0].roomID,
    options: SpectraChatSendMessageOptions(
        text: "hello",
        idempotencyKey: UUID().uuidString
    )
)

let left = try await chat.leaveRoom(
    roomID: rooms[0].roomID,
    options: SpectraChatMembershipRequestOptions(timeout: 10)
)

let membership = try await chat.getRoomMembership(
    roomID: rooms[0].roomID,
    options: SpectraChatMembershipRequestOptions(timeout: 10)
)
```

WebSocket transport도 SDK가 소유한다. 앱은 realtime client를 만들고 event stream만 구독하면 된다.

```swift
let realtime = SpectraChatRealtimeClient(client: chat)
let events = await realtime.eventStream()

try await realtime.connect()
try await realtime.setTyping(true, roomID: "room_123")

let acknowledged = try await realtime.sendTextMessage(
    roomID: "room_123",
    text: "hello"
)

for await event in events {
    switch event {
    case .message(let event):
        print(event.message.content.text ?? "")
    case .membership(let event):
        print(event.status.rawValue)
    default:
        break
    }
}
```

StorageSDK를 함께 쓰면 이미지/파일/음성 첨부 업로드와 메시지 전송을 한 번에
처리할 수 있다.

```swift
import SpectraStorageSDK

let storage = SpectraStorageClient(
    configuration: SpectraStorageClientConfiguration(
        baseURL: URL(string: "https://storage.spectra.kr")!,
        projectId: "project_123"
    ),
    tokenProvider: storageTokenProvider
)

let attachmentSender = SpectraChatStorageAttachmentSender(
    chat: chat,
    storage: storage
)

let chatWithStorage = SpectraChatClient(
    projectId: "project_123",
    tokenProvider: ChatTokenProvider(auth: authClient),
    storageClient: storage
)

let messageWithFiles = try await chatWithStorage.sendMessageWithFiles(
    roomID: "room_123",
    options: SpectraChatSendMessageWithFilesOptions(
        text: "첨부 확인",
        files: [
            SpectraChatFileDescriptor(
                data: fileData,
                name: "camp-photo.jpg",
                contentType: "image/jpeg"
            )
        ]
    )
)

try await attachmentSender.sendImageMessage(
    roomID: "room_123",
    imageData: imageData,
    contentType: "image/jpeg",
    caption: "사진",
    clientMessageID: UUID().uuidString
)
```

SDK가 소켓과 REST를 소유하더라도 앱 화면은 로컬 cache와 pending queue가 필요하다.
네트워크 실패 시에는 message draft를 queue에 넣고, 연결이 복구되면 flush한다.

```swift
let store = SpectraChatInMemoryStore()
let queue = SpectraChatOfflineSendQueue()

await store.upsertMessages(try await chat.listMessages(roomID: "room_123"))

await queue.enqueue(
    roomID: "room_123",
    content: SpectraChatSendContent(kind: "text", text: "나중에 전송"),
    clientMessageID: UUID().uuidString
)

let flushResult = await queue.flush(using: chat)
await store.upsertMessages(flushResult.sentMessages)
```

이전 메시지 pagination은 상태 객체가 `before_sequence`를 관리한다.

```swift
let paginator = SpectraChatMessagePaginator(
    client: chat,
    roomID: "room_123",
    limit: 30
)

let page = try await paginator.loadNextPage()
await store.upsertMessages(page.messages)
```

## 로컬 검증

```bash
swift package describe
swift test
```

## 현재 미완료 경계

- 실제 네트워크 reconnect/backoff UX를 앱 화면 정책에 맞춰 더 세밀화
- durable disk cache와 gap recovery policy
- 실제 Spectra iOS 앱 integration
- Modo Camp iOS 앱 integration
- 실제 message send → Chat outbox → Notification push 기기 수신 E2E
