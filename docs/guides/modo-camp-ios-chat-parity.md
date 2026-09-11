# Modo Camp iOS Chat SDK parity draft

Last checked: 2026-09-11

This guide fixes the Swift Chat SDK target for Modo Camp iOS. It is based on
the local `@spectra-platform/chat-sdk@0.2.0` source and the current
`chat-sdk-ios` implementation.

## Current state

- Existing SwiftPM package: `SpectraChatSDK`
- Current iOS package implements REST room/message/read APIs, WebSocket runtime,
  event decoding, Storage attachment helpers, in-memory store and offline send
  queue.
- Current iOS package still differs from JS `0.2.0` in app-facing naming and
  membership APIs. JS has `leaveRoom(roomId, { timeoutMs, signal })`,
  `getRoomMembership(...)`, `uploadFiles()`, `sendMessageWithFiles()` and
  `membership` events as the public contract.
- Modo backend conversation remains the final authority. Spectra realtime
  events are invalidation/refetch triggers, not the source of truth for Modo
  conversation state.

## Recommended package structure

Keep the existing separate SwiftPM package:

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    .upToNextMinor(from: "0.1.0")
)
```

`SpectraChatSDK` may depend on `SpectraStorageSDK` for attachment convenience,
as it already does. Do not create a new mono-package for this slice.

## Modo Camp configuration

```swift
let chat = SpectraChatClient(
    configuration: .init(
        baseURL: URL(string: "https://chat.spectra.kr")!,
        socketURL: URL(string: "wss://chat.spectra.kr/v1/socket"),
        projectId: "13d7ce4b-dd2a-4267-b15f-bbdb80b853da"
    ),
    tokenProvider: chatTokenProvider
)
```

`chatTokenProvider` must obtain `auth.getAccessToken(service: .chat)`. File
helpers that upload bytes must obtain `auth.getAccessToken(service: .storage)`
through Storage SDK. Neither token should be used for Modo backend bootstrap.

## Swift public API target

```swift
public struct SpectraChatMembershipRequestOptions: Sendable {
    public var timeout: Duration?
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

public actor SpectraChatClient {
    public func createDirectRoom(userID: String) async throws -> SpectraChatRoom
    public func createGroupRoom(title: String?, userIDs: [String]) async throws -> SpectraChatRoom
    public func listRooms(limit: Int?) async throws -> [SpectraChatRoom]
    public func listMessages(roomID: String, beforeSequence: Int64?, limit: Int?) async throws -> [SpectraChatMessage]
    public func sendMessage(roomID: String, options: SpectraChatSendMessageOptions) async throws -> SpectraChatMessage
    public func uploadFiles(roomID: String, options: SpectraChatUploadFilesOptions) async throws -> [SpectraChatStorageObjectReference]
    public func sendMessageWithFiles(roomID: String, options: SpectraChatSendMessageWithFilesOptions) async throws -> SpectraChatMessage
    public func markRead(roomID: String, lastReadSequence: Int64) async throws
    public func leaveRoom(roomID: String, options: SpectraChatMembershipRequestOptions) async throws -> SpectraChatLeaveRoomResult
    public func getRoomMembership(roomID: String, options: SpectraChatMembershipRequestOptions) async throws -> SpectraChatRoomMembership
}

public actor SpectraChatRealtimeClient {
    public func connect(roomID: String?) async throws
    public func disconnect() async
    public func setTyping(_ isTyping: Bool, roomID: String) async throws
    public func events() -> AsyncStream<SpectraChatEvent>
}
```

Swift cancellation should use task cancellation. `leaveRoom` and
`getRoomMembership` need a per-call deadline that covers token acquisition,
HTTP request and response parsing. A cancelled leave cannot be treated as a
rollback; the app should confirm membership before removing or restoring UI.

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

## JS to Swift parity checklist

| JS 0.2.0 | Swift target | Current iOS state |
| --- | --- | --- |
| `listRooms(options?)` | `listRooms(limit:)` | Implemented with different model names |
| `createDirectRoom({ userId })` | `createDirectRoom(userID:)` | Implemented |
| `createGroupRoom({ title, userIds })` | `createGroupRoom(title:userIDs:)` | Implemented |
| `listMessages(roomId, options?)` | `listMessages(roomID:beforeSequence:limit:)` | Implemented |
| `sendMessage(roomId, options)` | `sendMessage(roomID:options:)` | Implemented |
| `uploadFiles(roomId, options)` | `uploadFiles(roomID:options:)` | Attachment helper exists; parity alias needed |
| `sendMessageWithFiles(roomId, options)` | `sendMessageWithFiles(roomID:options:)` | Attachment helper exists; parity alias needed |
| `markRead(roomId, { lastReadSequence })` | `markRead(roomID:lastReadSequence:)` | Implemented |
| `setTyping(roomId, isTyping)` | `setTyping(_:roomID:)` | Implemented in realtime client |
| `connect(roomId?)` / `disconnect()` | realtime `connect` / `disconnect` | Implemented |
| `leaveRoom(roomId, { timeoutMs, signal })` | `leaveRoom(roomID:options:)` | Missing |
| `getRoomMembership(...)` | `getRoomMembership(roomID:options:)` | Missing |
| `membership` event | `.membership(...)` | Missing |
