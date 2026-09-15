# Modo Camp iOS Chat SDK parity draft

Last checked: 2026-09-15

This guide fixes the Swift Chat SDK target for Modo Camp iOS. It is based on
the local `@spectra-platform/chat-sdk@0.2.0` source and the current
`chat-sdk-ios` implementation.

## Current state

- Existing SwiftPM package: `SpectraChatSDK`
- Current iOS package implements REST room/message/read APIs, AuthSDK `.chat`
  service token convenience, WebSocket ticket runtime, event decoding, Storage
  attachment helpers, in-memory store and offline send queue.
- Current iOS package exposes JS `0.2.0` parity naming for room/message/file
  helpers, membership APIs, membership events, delegate/logger diagnostics and
  SDK-owned subscribed-room filtering. The legacy Swift event stream remains for
  compatibility, and `eventStream()` provides JS-style event cases.
- Modo backend conversation remains the final authority. Spectra realtime
  events are invalidation/refetch triggers, not the source of truth for Modo
  conversation state.

## Recommended package structure

Keep the existing separate SwiftPM package:

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    .upToNextMinor(from: "0.2.0")
)
```

`SpectraChatSDK` depends on `SpectraAuthSDK` for the app-facing
`SpectraChatClient(auth:)` path and `SpectraStorageSDK` for attachment
convenience. Do not create a new mono-package for this slice. Because
`auth-sdk-ios` currently requires iOS 17/macOS 14, `chat-sdk-ios` now matches
that minimum platform.

## Modo Camp configuration

```swift
let chat = SpectraChatClient(
    auth: auth,
    configuration: .init(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        socketURL: URL(string: "wss://chat.spectra.kr/v1/socket")!,
        projectId: "13d7ce4b-dd2a-4267-b15f-bbdb80b853da"
    )
)
```

`SpectraChatClient(auth:)` obtains `auth.getAccessToken(for: .chat)` inside the
SDK. File helpers that upload bytes still obtain Storage tokens through Storage
SDK. Neither token should be used for Modo backend bootstrap.

## Swift public API target

```swift
public struct SpectraChatMembershipRequestOptions: Sendable {
    public var timeout: TimeInterval?
}

public enum SpectraChatRoomMembershipStatus: String, Codable, Sendable {
    case active
    case left
}

public struct SpectraChatRoomMembership: Codable, Sendable {
    public var roomID: String
    public var appUserID: String
    public var status: SpectraChatRoomMembershipStatus
    public var leftAt: Date?
}

public typealias SpectraChatLeaveRoomResult = SpectraChatRoomMembership

public struct SpectraChatFileDescriptor: Sendable {
    public var data: Data
    public var name: String?
    public var path: String?
    public var contentType: String?
    public var metadata: [String: String]
    public var storageMetadata: [String: String]
}

public struct SpectraChatFileUploadProgress: Sendable {
    public var index: Int
    public var totalFiles: Int
    public var fileName: String
    public var objectKey: String
    public var loaded: Int64
    public var total: Int64
}

public enum SpectraChatEvent: Sendable {
    case message(SpectraChatMessageEvent)
    case typing(SpectraChatTypingEvent)
    case read(SpectraChatReadEvent)
    case membership(SpectraChatMembershipEvent)
    case connected(SpectraChatConnectionEvent)
    case disconnected(SpectraChatConnectionEvent)
    case error(SpectraChatErrorEvent)
}

public final class SpectraChatClient {
    public convenience init(auth: any ServiceTokenProvider, ...)
    public func createDirectRoom(userID: String) async throws -> SpectraChatRoom
    public func createGroupRoom(title: String?, userIDs: [String]) async throws -> SpectraChatRoom
    public func listRooms(limit: Int?) async throws -> [SpectraChatRoom]
    public func getRoom(roomID: String) async throws -> SpectraChatRoom
    public func listMessages(roomID: String, beforeSequence: Int64?, limit: Int?) async throws -> [SpectraChatMessage]
    public func connect() async throws
    public func subscribe(roomID: String) async throws
    public func connect(roomID: String) async throws
    public func sendMessage(roomID: String, text: String) async throws -> SpectraChatMessage
    public func sendMessage(roomID: String, options: SpectraChatSendMessageOptions) async throws -> SpectraChatMessage
    public func uploadFiles(roomID: String, options: SpectraChatUploadFilesOptions) async throws -> [SpectraChatStorageObjectReference]
    public func sendMessageWithFiles(roomID: String, options: SpectraChatSendMessageWithFilesOptions) async throws -> SpectraChatMessage
    public func markRead(roomID: String, lastReadSequence: Int64) async throws
    public func markRead(roomID: String, sequence: Int64) async throws
    public func setTyping(roomID: String, isTyping: Bool) async throws
    public func leaveRoom(roomID: String, options: SpectraChatMembershipRequestOptions) async throws -> SpectraChatLeaveRoomResult
    public func getRoomMembership(roomID: String, options: SpectraChatMembershipRequestOptions) async throws -> SpectraChatRoomMembership
}

public actor SpectraChatRealtimeClient {
    public func connect(roomID: String?) async throws
    public func subscribe(roomID: String) async throws
    public func disconnect()
    public func setTyping(_ isTyping: Bool, roomID: String) async throws
    public func eventStream() -> AsyncStream<SpectraChatEvent>
}
```

`getRoom(roomID:)` is implemented as a compatibility helper over `listRooms()`
because the current server contract does not expose `GET /v1/chat/rooms/{room_id}`.
Add that server endpoint if Modo needs direct single-room lookup at scale.

Swift cancellation uses task cancellation. `leaveRoom` and
`getRoomMembership` need a per-call deadline that covers token acquisition,
HTTP request and response parsing. The public timeout is seconds-based
`TimeInterval`; it maps to JS `timeoutMs` semantically and defaults to 10
seconds. A cancelled leave cannot be treated as a rollback; the app should
confirm membership before removing or restoring UI.

## Realtime authority rule for Modo

Modo's own backend conversation model is the final authority. Chat realtime
events should trigger refetch or invalidation:

- `message`: refetch visible conversation messages or append then reconcile.
- `typing`: transient UI only.
- `read`: update optimistic read state, then reconcile with backend if needed.
- `membership`: remove or refetch the affected room only.
- `connected`: refetch current room/messages because server replay is not
  guaranteed.
- `error`: surface safe code/status/requestId and keep local state conservative.

## Diagnostics and errors

Expose only safe fields:

- `code`
- `status`
- `requestId`
- `message`
- `retryable`

Preserve Auth errors such as `APP_SESSION_UNAUTHORIZED` when service token
issuance fails. Do not log access tokens, refresh tokens, message attachment
signed URLs, raw file names, raw message text, provider payloads or server
credential material.

Logger event names should align with JS concepts: `socket connecting`,
`connected`, `room subscribed`, `message received`, `typing received`,
`read received`, `token refreshed`, `reconnecting`, `disconnected`, `error`.
Safe fields are `roomID`, `connectionID`, `attempt`, `closeCode`, `errorCode`,
`requestID`, `retryAfter`, `messageID`, and `sequence`.

## Server contract notes

- Realtime subscribe uses `POST /v1/chat/rooms/{room_id}/websocket-ticket`, then
  `/v1/socket?ticket=...`. Tickets are opaque one-time credentials and are never
  exposed through logger fields.
- The current server does not document direct room creation idempotency for the
  same user pair. Treat duplicate direct room reuse as unconfirmed until the
  Chat server contract explicitly guarantees it.
- REST `sendMessage(roomID:text:)` returns the stored message directly. Socket
  `message.send` receives the sender's own `message.created` echo; the SDK
  treats the matching `clientMessageID` echo as the send ack.
- Room events require a real `room_id` or call `chat_room_id`. The SDK does not
  use `conversation_id` as a roomID fallback.

## JS to Swift parity checklist

| JS 0.2.0 | Swift target | Current iOS state |
| --- | --- | --- |
| `listRooms(options?)` | `listRooms(limit:)` | Implemented |
| `createDirectRoom({ userId })` | `createDirectRoom(userID:)` | Implemented |
| `createGroupRoom({ title, userIds })` | `createGroupRoom(title:userIDs:)` | Implemented |
| `getRoom(roomId)` | `getRoom(roomID:)` | Implemented via `listRooms()`; dedicated server endpoint missing |
| `listMessages(roomId, options?)` | `listMessages(roomID:beforeSequence:limit:)` | Implemented |
| `sendMessage(roomId, text/options)` | `sendMessage(roomID:text:)`, `sendMessage(roomID:options:)` | Implemented |
| `uploadFiles(roomId, options)` | `uploadFiles(roomID:options:)` | Implemented; requires injected Storage client |
| `sendMessageWithFiles(roomId, options)` | `sendMessageWithFiles(roomID:options:)` | Implemented; requires injected Storage client |
| `markRead(roomId, { lastReadSequence })` | `markRead(roomID:lastReadSequence:)` | Implemented |
| `setTyping(roomId, isTyping)` | `setTyping(roomID:isTyping:)`, realtime `setTyping(_:roomID:)` | Implemented |
| `connect(roomId?)` / `disconnect()` | `connect()`, `subscribe(roomID:)`, `connect(roomID:)`, `disconnect()` | Implemented with websocket-ticket |
| `leaveRoom(roomId, { timeoutMs, signal })` | `leaveRoom(roomID:options:)` | Implemented |
| `getRoomMembership(...)` | `getRoomMembership(roomID:options:)` | Implemented |
| `membership` event | `.membership(...)` | Implemented in `eventStream()` and legacy realtime event |

## Swift usage notes

File helpers need a Storage SDK client because Chat tokens and Storage tokens
remain separate.

```swift
let storage = SpectraStorageClient(
    configuration: .init(
        baseURL: URL(string: "https://storage.spectra.kr")!,
        projectId: "13d7ce4b-dd2a-4267-b15f-bbdb80b853da"
    ),
    tokenProvider: storageTokenProvider
)

let chat = SpectraChatClient(
    auth: auth,
    configuration: .init(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        socketURL: URL(string: "wss://chat.spectra.kr/v1/socket")!,
        projectId: "13d7ce4b-dd2a-4267-b15f-bbdb80b853da"
    ),
    storageClient: storage
)

let room = try await chat.createDirectRoom(userID: targetUserID)
try await chat.connect()
try await chat.subscribe(roomID: room.id)

let textMessage = try await chat.sendMessage(
    roomID: room.id,
    text: "안녕하세요"
)

let message = try await chat.sendMessageWithFiles(
    roomID: room.id,
    options: SpectraChatSendMessageWithFilesOptions(
        text: "사진 공유",
        files: [
            SpectraChatFileDescriptor(
                data: imageData,
                name: "camp-photo.jpg",
                contentType: "image/jpeg"
            )
        ]
    )
)

let membership = try await chat.leaveRoom(
    roomID: room.id,
    options: SpectraChatMembershipRequestOptions(timeout: 10)
)
```
