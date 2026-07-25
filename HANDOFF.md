# HANDOFF — chat-sdk-ios

## 목적과 소유 범위

`chat-sdk-ios`는 Spectra Platform Chat의 iOS 공개 SDK를 소유한다. 앱이 Auth token provider를 주입하고 Chat REST API와 WebSocket realtime runtime을 안전하게 사용할 수 있게 한다.

이 저장소는 iOS SDK만 소유한다. Chat 서버, PostgreSQL, NATS/JetStream, Notification consumer, 앱 화면과 운영 배포는 각각 해당 저장소의 소유 범위다.

## 확정된 결정

- iOS 앱 bundle에는 internal service key, Chat DB credential, NATS credential, Notification provider credential을 넣지 않는다.
- SDK는 AuthSDK에 hard dependency를 두지 않고 `SpectraChatAccessTokenProviding` protocol을 주입받는다.
- `SpectraChatClientConfiguration.projectId`가 있으면 public request에 `X-Spectra-Project-Id`를 붙인다. 권한 판단은 app-user bearer token과 서버 Auth 검증이 소유한다.
- REST history와 room list는 PostgreSQL source of truth를 조회하는 public Chat API를 사용한다.
- SDK의 REST `sendMessage`는 server-side message transaction과 notification outbox trigger를 기대한다. SDK가 APNs/FCM을 직접 호출하지 않는다.
- WebSocket 실시간 전송은 `/v1/socket`과 `message.send`, `typing.set`, `read_cursor.update` command envelope를 따른다.
- WebSocket runtime은 SDK가 소유한다. `SpectraChatRealtimeClient`가 authenticated request 생성, `URLSessionWebSocketTask` 연결, receive loop, event stream, command 송신과 기본 reconnect 상태를 제공한다.
- Call over Chat socket은 lifecycle event만 decode한다. 지원 event는 `call.invited`, `call.accepted`, `call.declined`, `call.joined`, `call.left`, `call.ended`, `call.missed`이며 iOS CallKit·LiveKit 연결은 앱/CallSDK가 담당한다.
- Chat socket call payload에는 WebRTC SDP/ICE, LiveKit participant token, TURN credential, RTP data, provider secret을 실어서는 안 된다.
- ChatSDK는 push notification을 직접 발송하지 않는다. message transaction 뒤 수신자별 notification request outbox와 Notification consumer가 담당한다.
- Storage 첨부는 Storage SDK에 직접 의존하지 않고 `SpectraChatStorageObjectReference` 값 타입으로 경계를 둔다. `SpectraChatSendContent`와 `SpectraChatContent` 모두 `storage_object_references`를 보존해, 송신 payload와 history 응답이 같은 storage reference 경계를 유지한다.
- Swift Package Manager 배포는 Git URL 기반으로 시작한다. repository URL은 `https://github.com/Spectra-Platform/chat-sdk-ios.git`, product 이름은 `SpectraChatSDK`다.
- release tag는 `vMAJOR.MINOR.PATCH` 형식으로 만들며, 최초 tag는 공개 버전 번호를 확정한 뒤 생성한다.

## 현재 구현 경계

- Swift Package `SpectraChatSDK`가 생성됐다.
- `.github/workflows/ci.yml`이 SwiftPM resolve/describe/test를 검증한다.
- Public surface:
  - `SpectraChatClientConfiguration`
  - `SpectraChatAccessTokenProviding`
  - `StaticSpectraChatAccessTokenProvider`
  - `SpectraChatClient`
  - `SpectraChatCreateRoomRequest`
  - `SpectraChatRoom`
  - `SpectraChatMessage`
  - `SpectraChatContent`
  - `SpectraChatSendContent`
  - `SpectraChatStorageObjectReference`
  - `SpectraChatMediaItem`
  - `SpectraChatMediaReadURL`
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
  - `SpectraChatCallParticipant`
  - `SpectraChatCallTrace`
  - `SpectraChatError`
- Unit test는 bearer/project/idempotency header, REST path/query/body, send message decode, history decode, media read URL, socket request, command envelope, realtime event decode, call lifecycle event decode와 error decode를 검증한다.
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
- 실제 message send → Notification push 기기 수신 E2E

## 마지막으로 코드와 대조한 날짜

- 2026-07-25
