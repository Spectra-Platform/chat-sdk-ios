# HANDOFF — chat-sdk-ios

## 목적과 소유 범위

`chat-sdk-ios`는 Spectra Platform Chat의 iOS 공개 SDK를 소유한다. 앱이 Auth token provider를 주입하고 Chat REST API와 WebSocket realtime runtime을 안전하게 사용할 수 있게 한다.

이 저장소는 iOS SDK만 소유한다. Chat 서버, PostgreSQL, NATS/JetStream, Notification consumer, 앱 화면과 운영 배포는 각각 해당 저장소의 소유 범위다.

## 확정된 결정

- iOS 앱 bundle에는 internal service key, Chat DB credential, NATS credential, Notification provider credential을 넣지 않는다.
- SDK는 AuthSDK `0.1.2`에 hard dependency를 두고 `SpectraChatClient(auth:)`에서 `ServiceTokenProvider`를 감싸 `.chat` service token 발급/refresh를 내부 처리한다. 기존 `SpectraChatAccessTokenProviding` protocol 기반 초기화는 compatibility로 유지한다.
- AuthSDK dependency 때문에 ChatSDK minimum platform은 iOS 17/macOS 14로 맞춘다. 이 변경 없이 직접 Auth object initializer를 제공하면 SwiftPM이 macOS 12/iOS 15 package compatibility 오류로 build를 막는다.
- `SpectraChatClientConfiguration.projectId`가 있으면 public request에 `X-Spectra-Project-Id`를 붙인다. 권한 판단은 app-user bearer token과 서버 Auth 검증이 소유한다.
- REST history와 room list는 PostgreSQL source of truth를 조회하는 public Chat API를 사용한다.
- SDK의 REST `sendMessage`는 server-side message transaction과 notification outbox trigger를 기대한다. SDK가 APNs/FCM을 직접 호출하지 않는다.
- WebSocket 실시간 전송은 room별 `POST /v1/chat/rooms/{room_id}/websocket-ticket`을 발급받아 `/v1/socket?ticket=...`에 연결하고, `message.send`, `typing.set`, `read_cursor.update` command envelope를 따른다. Reconnect마다 새 ticket을 발급한다.
- `SpectraChatClient.connect()`, `subscribe(roomID:)`, `connect(roomID:)`, `setTyping(roomID:isTyping:)`가 앱-facing realtime convenience다. 앱은 raw `URLSessionWebSocketTask`, reconnect, ticket/token refresh와 room event filtering을 직접 구현하지 않는다.
- room event는 실제 `room_id` 또는 call payload의 `chat_room_id`가 있어야 한다. SDK는 `conversation_id`를 roomID fallback으로 사용하지 않고 `ROOM_ID_REQUIRED`를 반환한다.
- `SpectraChatClientConfiguration.socketURL`이 명시되면 WebSocket request는 REST `baseURL`에서 추론하지 않고 해당 URL을 그대로 사용한다. Gateway 또는 Local Debug처럼 REST API host와 WebSocket host가 분리된 consumer가 SDK-owned realtime runtime을 유지하기 위한 경계다. 명시 값이 없으면 기존처럼 `baseURL`의 scheme을 `ws/wss`로 바꾸고 `/v1/socket`을 붙인다.
- WebSocket runtime은 SDK가 소유한다. `SpectraChatRealtimeClient`가 authenticated request 생성, `URLSessionWebSocketTask` 연결, receive loop, event stream, command 송신과 기본 reconnect 상태를 제공한다.
- Call lifecycle realtime event는 `server_sequence`를 public `SpectraChatCallLifecycleEvent.serverSequence`로 노출한다. 앱 consumer는 이 값을 재연결 gap 복구 cursor와 중복 제거에 사용한다.
- Call over Chat socket은 lifecycle event만 decode한다. 지원 event는 `call.invited`, `call.state_updated`, `call.accepted`, `call.declined`, `call.joined`, `call.left`, `call.ended`, `call.missed`이며 iOS CallKit·LiveKit 연결은 앱/CallSDK가 담당한다.
- Call lifecycle decoder는 기존 flattened event, top-level `call` snapshot, Community Chat socket envelope(`payload.call`, `payload.change_type`, `payload.actor_user_id`)를 모두 지원한다. Community envelope의 `call.state/kind/participants[].user_id`와 `payload.call.state/kind/participants[].user_id`는 SDK의 기존 `status/callType/participants[].appUserID` public surface로 정규화된다.
- Call lifecycle decoder는 `initiator_user_id`를 `SpectraChatCallSummary.initiatorUserID`로 보존한다. 앱 consumer는 수신자가 먼저 `accepted/connected`가 된 `call.state_updated`에서도 participant state를 기반으로 발신자를 추측하지 않고 이 값을 우선 사용해야 한다.
- Chat socket call payload에는 WebRTC SDP/ICE, LiveKit participant token, TURN credential, RTP data, provider secret을 실어서는 안 된다.
- ChatSDK는 push notification을 직접 발송하지 않는다. message transaction 뒤 수신자별 notification request outbox와 Notification consumer가 담당한다.
- Storage 첨부는 Storage SDK에 직접 의존하지 않고 `SpectraChatStorageObjectReference` 값 타입으로 경계를 둔다. `SpectraChatSendContent`와 `SpectraChatContent` 모두 `storage_object_references`를 보존해, 송신 payload와 history 응답이 같은 storage reference 경계를 유지한다.
- Swift Package Manager 배포는 Git URL 기반으로 시작한다. repository URL은 `https://github.com/Spectra-Platform/chat-sdk-ios.git`, product 이름은 `SpectraChatSDK`다.
- release tag는 `vMAJOR.MINOR.PATCH` 형식으로 만들며, 최초 tag는 공개 버전 번호를 확정한 뒤 생성한다.
- 2026-09-11 Modo Camp iOS parity 목표는 React 웹 `@spectra-platform/chat-sdk@0.2.0`의
  room/message/attachment/realtime/membership 의미를 Swift에도 맞추는 것이다. Modo backend
  conversation이 최종 authority이고, Spectra realtime event는 refetch/invalidation trigger로만 사용한다.
- Swift parity API에는 `leaveRoom(roomID:options:)`, `getRoomMembership(roomID:options:)`,
  `uploadFiles(roomID:options:)`, `sendMessageWithFiles(roomID:options:)`와 membership event가 필요하다.
  timeout/cancel은 task cancellation과 per-call deadline으로 처리하되, 취소된 leave를 rollback으로 간주하지 않는다.
- membership timeout은 `TimeInterval` seconds 단위 public option으로 제공한다. JS `timeoutMs`와 의미는 같고 기본값은 10초다.
- `SpectraChatClient`의 file parity helper는 주입된 `SpectraStorageClient`를 사용한다. storage token은
  StorageSDK token provider가 가져오며 ChatSDK는 storage token 원문, signed URL, 파일명 원문을 diagnostic으로 출력하지 않는다.
- 2026-09-15 room-centric DX 구현에서 `SpectraChatRoom.id`, `getRoom(roomID:)`, `sendMessage(roomID:text:)`,
  `markRead(roomID:sequence:)`, delegate/logger를 추가했다. `getRoom(roomID:)`는 현재 서버에 dedicated
  `GET /v1/chat/rooms/{room_id}`가 없어 `listRooms()`에서 찾는 compatibility helper다.
- Direct room 생성의 same-pair idempotency는 현재 서버 계약에 명시되어 있지 않다. Modo Camp가 같은 user pair에 같은 room 재사용을 요구하면 Chat 서버 계약과 테스트가 먼저 추가되어야 한다.
- REST `sendMessage(roomID:text:)`는 저장된 message를 바로 반환한다. socket `message.send`는 sender 본인에게도 `message.created` echo가 오며, SDK는 같은 `clientMessageID` echo를 send ack로 간주한다.

## 현재 구현 경계

- Swift Package `SpectraChatSDK`가 생성됐다.
- `.github/workflows/ci.yml`이 SwiftPM resolve/describe/test를 검증한다.
- Public surface:
  - `SpectraChatClientConfiguration`
  - `SpectraChatAccessTokenProviding`
  - `SpectraChatAccessTokenRefreshing`
  - `SpectraChatAuthServiceTokenProvider`
  - `StaticSpectraChatAccessTokenProvider`
  - `SpectraChatLogLevel`
  - `SpectraChatLogger`
  - `SpectraChatClientDelegate`
- `SpectraChatClient`
  - `SpectraChatCreateRoomRequest`
  - `SpectraChatRoom`
  - `SpectraChatMessage`
  - `SpectraChatContent`
  - `SpectraChatSendContent`
  - `SpectraChatStorageObjectReference`
  - `SpectraChatMediaItem`
  - `SpectraChatMediaReadURL`
  - `SpectraChatWebSocketTicket`
  - `SpectraChatRealtimeClient`
  - `SpectraChatRealtimeEvent`
  - `SpectraChatRealtimeConnectionState`
  - `SpectraChatRealtimeError`
  - `SpectraChatReadCursorUpdated`
  - `SpectraChatTypingSet`
  - `SpectraChatTypingUpdated`
  - `SpectraChatServerError`
  - `SpectraChatCommandEnvelope`
  - `SpectraChatSendMessage`
  - `SpectraChatReadCursorUpdate`
  - `SpectraChatCallLifecycleEvent`
  - `SpectraChatCallEventType`
  - `SpectraChatCallActor`
  - `SpectraChatCallSummary`
    - `initiatorUserID`
  - `SpectraChatCallParticipant`
  - `SpectraChatCallTrace`
  - `SpectraChatError`
  - `SpectraChatSendMessageOptions`
  - `SpectraChatMembershipRequestOptions`
  - `SpectraChatRoomMembershipStatus`
  - `SpectraChatRoomMembership`
  - `SpectraChatLeaveRoomResult`
  - `SpectraChatMembershipEvent`
  - `SpectraChatFileDescriptor`
  - `SpectraChatFileUploadProgress`
  - `SpectraChatUploadFilesOptions`
  - `SpectraChatFileUploadOptions`
  - `SpectraChatSendMessageWithFilesOptions`
  - `SpectraChatEvent`
  - `SpectraChatMessageEvent`
  - `SpectraChatTypingEvent`
  - `SpectraChatReadEvent`
  - `SpectraChatConnectionEvent`
  - `SpectraChatErrorEvent`
- Unit test는 bearer/project/idempotency header, REST path/query/body, send message decode, history decode, media read URL, socket request, command envelope, realtime event decode, call lifecycle event decode와 error decode를 검증한다.
- 2026-09-15 unit test는 Auth object token provider, roomID required failure, logger redaction, websocket ticket request와 subscribed-room event filtering을 추가로 검증한다.
- Modo Camp parity unit test는 JS naming alias, send options, leave/membership endpoint, membership timeout,
  uploadFiles/sendMessageWithFiles StorageSDK bridge, membership event와 `SpectraChatEvent` decode를 검증한다.
- socket request test는 REST `baseURL` 추론 경로와 explicit `socketURL` override 경로를 모두 검증한다.
- iOS 앱 통합 기준 문서는 `docs/guides/ios-chat-sdk-integration.md`에 둔다.
- SwiftPM 릴리즈 기준은 `docs/guides/release-checklist.md`에 둔다.

## 변경 시 함께 확인할 계약·저장소

- `spectra-chat`: REST/WebSocket producer, message/history/outbox
- `Spectra-Platform/auth-sdk-ios`: app user token provider adapter
- `Spectra-Platform/notification-sdk-ios`: APNs device registration과 push deep link
- `spectra-notification` 또는 `Spectra-Platform/delivery-platform`: message push consumer
- `spectra-ios`: chat 화면, WebSocket runtime, foreground sound/banner suppression

## 남은 작업과 미확정 항목

- 앱의 기존 `URLSessionChatSocketClient`를 `SpectraChatRealtimeClient`로 교체하는 integration
- 실제 네트워크 reconnect/backoff UX와 foreground push dedupe를 앱 화면 정책에 맞춰 조율
- iOS 앱의 rich media upload flow와 Storage SDK object reference 연결
- 실제 Spectra iOS 앱 integration
- 실제 Modo Camp iOS SwiftUI 앱 integration
- 실제 message send → Notification push 기기 수신 E2E
- 새 explicit socket URL surface를 Spectra iOS SPM pin에 반영하고, Local Debug에서 Community API room/history와 같은 socket endpoint를 ChatSDK realtime runtime이 사용하는지 확인
- Modo Camp parity: 실제 Live 사용자 bearer/session으로 leave 후 list/messages/send/setTyping/websocket-ticket 차단과
  남은 참가자 history 유지 E2E 검증

## 마지막으로 코드와 대조한 날짜

- 2026-09-15 문서와 현재 public API를 Modo Camp room-centric DX 구현 기준으로 재대조했다. 코드 구현 경계는
  AuthSDK 직접 주입, room/message/file/realtime/membership surface, SDK-owned websocket-ticket subscribe,
  logger/delegate와 subscribed-room filtering을 Swift에서 사용할 수 있는 상태이며, 실제 Modo Camp iOS 앱·실기기·Live 사용자 세션 E2E는 남아 있다.
