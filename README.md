# Spectra Chat SDK for iOS

Swift Package 기반의 Spectra Platform Chat iOS SDK다. 앱이 raw WebSocket, Chat service token refresh, reconnect, room event filtering을 직접 관리하지 않아도 되도록 Chat REST API와 WebSocket realtime runtime을 제공한다.

## 현재 구현 상태

- Swift Package: `SpectraChatSDK`
- Package URL: `https://github.com/Spectra-Platform/chat-sdk-ios.git`
- Minimum platform: iOS 17 / macOS 14. AuthSDK의 `ServiceTokenProvider`를 직접 주입받아 `.chat` service token을 발급/refresh하기 위해 AuthSDK `0.1.2`와 맞춘다.
- Public configuration: SDK-owned production `baseURL`/`socketURL`, `projectId`
- Public token provider: `SpectraChatClient(auth:)` AuthSDK convenience, 기존 `SpectraChatAccessTokenProviding`
- REST API:
  - `GET /v1/chat/rooms`
  - `getRoom(roomID:)` compatibility helper. 현재 Chat 서버에는 `GET /v1/chat/rooms/{room_id}` 전용 endpoint가 없어 SDK가 `listRooms()` 결과에서 찾는다.
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
  - `POST /v1/chat/rooms/{room_id}/websocket-ticket` 발급 후 `/v1/socket?ticket=...` 연결
  - `SpectraChatClient.connect()` / `subscribe(roomID:)` / `connect(roomID:)` / `disconnect()`
  - `events()` `AsyncStream<SpectraChatRealtimeEvent>`
  - `eventStream()` `AsyncStream<SpectraChatEvent>` JS parity stream
  - `SpectraChatClientDelegate`, `logger` closure
  - subscribed room 기준 SDK 내부 event filtering
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
    .upToNextMinor(from: "0.2.0")
)
```

target dependency:

```swift
.product(name: "SpectraChatSDK", package: "chat-sdk-ios")
```

ChatSDK는 AuthSDK `SpectraAuthSDK`와 StorageSDK `SpectraStorageSDK`를 package dependency로 사용한다. 앱 target은 일반적으로 `SpectraChatSDK`만 직접 연결하면 된다.

## 사용 예시

Modo Camp의 JS SDK parity 목표와 membership/attachment Swift API 초안은
[Modo Camp iOS Chat SDK parity draft](docs/guides/modo-camp-ios-chat-parity.md)에
별도로 정리한다.

```swift
import SpectraAuthSDK
import SpectraChatSDK

let auth = SpectraAuthClient(...)

let chat = SpectraChatClient(
    auth: auth,
    configuration: .production(projectId: "project_123")
)

chat.delegate = self
chat.logger = { level, event, fields in
    print("[spectra-chat]", level, event, fields)
}

let room = try await chat.createDirectRoom(userID: targetUserID)

try await chat.connect()
try await chat.subscribe(roomID: room.roomID)

let message = try await chat.sendMessage(
    roomID: room.roomID,
    text: "안녕하세요",
    idempotencyKey: UUID().uuidString
)

try await chat.markRead(roomID: room.roomID, sequence: message.serverSequence)
try await chat.setTyping(roomID: room.roomID, isTyping: true)
```

기존 token provider 기반 초기화는 호환 경로로 유지된다.

```swift
let chat = SpectraChatClient(
    projectId: "project_123",
    tokenProvider: chatTokenProvider
)
```

WebSocket transport도 SDK가 소유한다. 앱은 raw `URLSessionWebSocketTask`를 만들 필요가 없다.

```swift
let realtime = SpectraChatRealtimeClient(client: chat)
let events = await realtime.eventStream()

try await realtime.connect()
try await realtime.subscribe(roomID: "room_123")

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
    auth: auth,
    configuration: .production(projectId: "project_123"),
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

## Realtime 정책

- `subscribe(roomID:)`는 서버의 `POST /v1/chat/rooms/{room_id}/websocket-ticket`으로 one-time ticket을 받은 뒤 `/v1/socket?ticket=...`에 연결한다. token 원문과 ticket 원문은 logger fields에 남기지 않는다.
- 서버 MVP는 disconnected event replay를 제공하지 않는다. `connection.ready` 이후 앱은 필요한 room/history/read cursor를 REST로 다시 맞춘다.
- SDK는 subscribed roomID와 맞는 `message`, `typing`, `read`, `membership`, `call` event만 앱 delegate/stream으로 전달한다. `conversationID`는 `roomID` fallback으로 사용하지 않는다.
- `sendMessage(roomID:text:)` REST 호출은 저장된 `SpectraChatMessage`를 바로 반환한다. socket `message.send`는 서버가 같은 sender에게도 `message.created`를 echo하며, SDK는 `clientMessageID`가 같은 echo를 send ack로 간주한다.
- Direct room 생성의 idempotency는 현재 서버에서 “동일 참가자 재사용” 계약으로 문서화되어 있지 않다. 같은 pair가 항상 같은 room을 반환해야 한다면 Chat 서버에 dedicated idempotency 계약이 추가되어야 한다.
- logger event 이름은 `socket connecting`, `connected`, `room subscribed`, `message received`, `typing received`, `read received`, `token refreshed`, `reconnecting`, `disconnected`, `error`를 사용한다. fields는 `roomID`, `connectionID`, `attempt`, `closeCode`, `errorCode`, `requestID`, `retryAfter`, `messageID`, `sequence` 같은 안전 필드만 사용한다.

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
