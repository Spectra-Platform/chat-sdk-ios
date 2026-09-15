# WORKLOG — chat-sdk-ios

## 2026-09-15 — SwiftPM `v0.2.0` room-first release

- 상태: 완료, Modo Camp iOS 앱·실기기 Live 세션 E2E는 미수행
- 목적: Modo Camp가 설치 가능한 SwiftPM tag로 room-first Chat SDK API를 확인할 수 있게 한다.
- 결과: `origin/main`에 `96eb8ca9e16985eb612dfab11788387e43f3c5e8` room-first 변경을 push했고, 같은 commit을 가리키는 annotated tag `v0.2.0`을 원격에 push했다.
- 검증 상태: `swift test` 40 tests 통과, `git diff --check` 통과, `git ls-remote`로 `origin/main`과 `refs/tags/v0.2.0` 원격 반영을 확인했다.
- 남음: 실제 Modo Camp iOS 앱에서 SwiftPM resolution, Live Auth session, realtime subscribe/send E2E 검증.

## 2026-09-15 — Modo Camp room-centric Chat SDK DX

- 상태: 완료, Modo Camp iOS 앱·실기기 Live 세션 E2E는 미수행
- 목적: Modo Camp가 raw WebSocket, Chat token refresh, reconnect, room event filtering을 직접 관리하지 않고
  AuthSDK 객체와 room 중심 API만으로 Chat realtime platform layer를 사용할 수 있게 한다.
- 주요 변경 영역:
  - `SpectraChatClient(auth:)` AuthSDK `ServiceTokenProvider` convenience와 `.chat` service token adapter 추가
  - `getRoom(roomID:)`, `SpectraChatRoom.id`, `sendMessage(roomID:text:)`, `markRead(roomID:sequence:)`,
    `connect()`, `subscribe(roomID:)`, `connect(roomID:)`, `setTyping(roomID:isTyping:)` 추가
  - websocket-ticket 기반 subscribe/reconnect, subscribed-room event filtering, `ROOM_ID_REQUIRED`와
    conversationID fallback 금지 추가
  - delegate/logger, safe log fields, token/ticket redaction 테스트 추가
  - AuthSDK dependency 반영으로 minimum platform을 iOS 17/macOS 14로 조정
- 검증 상태: `swift test` 40 tests 통과, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-09-15-01-chat-sdk-room-centric-dx.md`](docs/work-logs/2026-09-15-01-chat-sdk-room-centric-dx.md)

## 2026-09-11 — Modo Camp Chat parity implementation

- 상태: 완료, Modo Camp iOS 앱·실기기 Live 세션 E2E는 미검증
- 목적: Modo Camp iOS SwiftUI가 JS `@spectra-platform/chat-sdk@0.2.0`과 같은 의미로
  room/message/file/realtime/membership API를 사용할 수 있도록 Swift public surface를 구현한다.
- 주요 변경 영역:
  - `createDirectRoom(userID:)`, `createGroupRoom(title:userIDs:)`, `sendMessage(roomID:options:)`,
    `markRead(roomID:lastReadSequence:)` parity naming 보강
  - `leaveRoom(roomID:options:)`, `getRoomMembership(roomID:options:)` REST API와 10초 기본 deadline,
    task cancellation error mapping 추가
  - `uploadFiles(roomID:options:)`, `sendMessageWithFiles(roomID:options:)` StorageSDK bridge 추가
  - `room.membership.updated` decode, legacy realtime `.membership`, JS-style `SpectraChatEvent`와 `eventStream()` 추가
  - JS SDK -> Swift SDK 매핑표와 Modo backend authority 문서 갱신
- 검증 상태: `swift test` 35 tests 통과, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-09-11-02-modo-camp-chat-parity-implementation.md`](docs/work-logs/2026-09-11-02-modo-camp-chat-parity-implementation.md)

## 2026-09-11 — Modo Camp Chat parity draft

- 상태: 문서 계약 초안 완료, leave/membership/file API parity 구현은 미완료
- 목적: Modo Camp iOS가 React 웹 Chat SDK `0.2.0`과 같은 의미의 room, message,
  attachment, realtime, membership API를 사용할 수 있도록 Swift public API 목표를 고정한다.
- 결과: `docs/guides/modo-camp-ios-chat-parity.md`에 Swift Chat API 초안,
  membership timeout/cancel 경계, Modo backend authority 원칙, diagnostics redaction과
  JS parity checklist를 추가했다.
- 검증: 문서 변경만 수행했다. Swift code는 변경하지 않았다.
- 상세 기록: [`docs/work-logs/2026-09-11-01-modo-camp-chat-parity.md`](docs/work-logs/2026-09-11-01-modo-camp-chat-parity.md)

## 2026-07-26 — Call initiator identity preservation

- 상태: 완료
- 목적: `call.state_updated`에서 수신자가 먼저 `connected`가 되어도 ChatSDK consumer가 발신자와 수신자를 뒤집어 판단하지 않도록 `initiator_user_id`를 public model에 보존한다.
- 주요 변경 영역:
  - `SpectraChatCallSummary.initiatorUserID` 추가
  - Community envelope/top-level call fixture에서 `initiator_user_id` decode 회귀 테스트 추가
  - 앱 consumer가 participant 상태 추측 대신 서버 initiator를 사용할 수 있는 경계 문서화
- 검증 상태: targeted `swift test`, 전체 `swift test`, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-26-04-call-initiator-identity.md`](docs/work-logs/2026-07-26-04-call-initiator-identity.md)

## 2026-07-26 — Top-level call payload participant decode

- 상태: 완료
- 목적: Community Chat socket이 call lifecycle event의 `call` snapshot을 top-level field로 전달할 때 SDK가 participant와 room 정보를 놓치지 않게 한다.
- 주요 변경 영역:
  - top-level `call` payload를 `CallLifecycleSocketCall`로 decode
  - top-level `call.chat_room_id`, `call.participants`, singular `call.participant` fallback 추가
  - `call.invited` top-level call fixture 회귀 테스트 추가
- 검증 상태: `swift test` 23 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-26-03-top-level-call-payload.md`](docs/work-logs/2026-07-26-03-top-level-call-payload.md)

## 2026-07-26 — Community call lifecycle envelope decode

- 상태: 완료
- 목적: Call Platform이 Chat lifecycle request를 Community Chat consumer canonical shape로 발행했을 때 iOS ChatSDK realtime decoder가 통화 초대와 상태 변경을 놓치지 않게 한다.
- 주요 변경 영역:
  - `call.state_updated` event type 추가
  - `payload.call`, `payload.change_type`, `payload.actor_user_id` nested envelope decode 추가
  - `state/kind/user_id`를 기존 `status/callType/appUserID` public surface로 정규화
  - 기존 flattened call lifecycle fixture 회귀 보존
- 검증 상태: `swift test` 22 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-26-02-community-call-lifecycle-envelope.md`](docs/work-logs/2026-07-26-02-community-call-lifecycle-envelope.md)

## 2026-07-26 — Explicit socket URL configuration

- 상태: 완료
- 목적: REST API base URL과 WebSocket endpoint가 분리된 consumer도 SDK-owned realtime runtime을 그대로 사용할 수 있게 한다.
- 주요 변경 영역:
  - `SpectraChatClientConfiguration.socketURL` 추가
  - 명시 socket URL 우선 사용, 없을 때 기존 `baseURL` 기반 `/v1/socket` 추론 유지
  - bearer/project header가 explicit socket URL에서도 유지되는 회귀 테스트 추가
- 검증 상태: `swift test` 20 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-26-01-explicit-socket-url.md`](docs/work-logs/2026-07-26-01-explicit-socket-url.md)

## 2026-07-25 — Call lifecycle server sequence exposure

- 상태: 완료
- 목적: SDK-owned realtime event를 앱의 재연결 gap 복구 cursor에 그대로 연결할 수 있도록 Call lifecycle event의 `server_sequence`를 public model에 노출한다.
- 주요 변경 영역:
  - `SpectraChatCallLifecycleEvent.serverSequence` 추가
  - singular/plural participant call lifecycle fixture의 server sequence decode 회귀 테스트 추가
- 검증 상태: `swift test` 15 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-25-05-call-lifecycle-server-sequence.md`](docs/work-logs/2026-07-25-05-call-lifecycle-server-sequence.md)

## 2026-07-25 — SDK-owned WebSocket realtime runtime

- 상태: 완료
- 목적: SDK 소비자가 앱에서 별도 WebSocket transport를 직접 만들지 않아도 Chat realtime을 사용할 수 있게 한다.
- 주요 변경 영역:
  - `SpectraChatRealtimeClient` 추가
  - authenticated socket 연결, receive loop, `events()` stream, command 송신과 기본 reconnect 상태 추가
  - `message.created`, `read_cursor.updated`, `typing.updated`, server error와 call lifecycle decode 추가
  - README/HANDOFF와 상세 작업 로그 갱신
- 검증 상태: `swift test` 15 tests 통과
- 상세 기록: [`2026-07-25-04-sdk-owned-websocket-runtime.md`](docs/work-logs/2026-07-25-04-sdk-owned-websocket-runtime.md)

## 2026-07-25 — Storage object references in received content

- 상태: 완료
- 목적: StorageSDK로 업로드한 첨부를 ChatSDK send path뿐 아니라 history/send 응답에서도 보존할 수 있게 한다.
- 주요 변경 영역:
  - `SpectraChatContent.storageObjectReferences` 추가
  - `storage_object_references` decode 회귀 테스트 추가
  - Storage 첨부 value type 경계 문서화
- 검증 상태: `swift test` 11 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-25-03-storage-object-references-in-content.md`](docs/work-logs/2026-07-25-03-storage-object-references-in-content.md)

## 2026-07-25 — Call lifecycle event decoder for Chat socket

- 상태: 완료
- 목적: Call Platform이 Chat socket을 lifecycle fan-out 경로로 사용할 수 있도록 iOS ChatSDK에 call lifecycle event decoder를 추가한다.
- 주요 변경 영역:
  - `call.invited`, `call.accepted`, `call.declined`, `call.joined`, `call.left`, `call.ended`, `call.missed` event type 추가
  - call summary, actor, participant, trace payload decoder 추가
  - Chat socket payload가 media transport credential을 소유하지 않는 경계 문서화
- 검증 상태: `swift test` 10 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-25-02-call-lifecycle-event-decoder.md`](docs/work-logs/2026-07-25-02-call-lifecycle-event-decoder.md)

## 2026-07-25 — Platform Chat SDK boundary refinement

- 상태: 완료
- 목적: 새 Spectra Platform 기준에 맞춰 ChatSDK의 public surface를 Auth token provider, project context, REST message send, WebSocket request, Storage attachment boundary로 보강한다.
- 주요 변경 영역:
  - `SpectraChatClientConfiguration.projectId`와 `X-Spectra-Project-Id` request header 추가
  - generic `createRoom`, REST `sendMessage`, `markRead`, `socketRequest` public API 추가
  - Storage SDK 직접 의존 없는 `SpectraChatStorageObjectReference` 추가
  - README, HANDOFF, integration guide 갱신
- 검증 상태: `swift test` 8 tests, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-25-01-platform-chat-sdk-boundary.md`](docs/work-logs/2026-07-25-01-platform-chat-sdk-boundary.md)

## 2026-07-24 — ChatSDK REST first SwiftPM bootstrap

- 상태: 완료
- 목적: iOS 앱에서 Auth token provider를 주입해 Chat REST API를 호출하고 WebSocket command envelope를 생성할 수 있는 첫 Swift Package를 만든다.
- 주요 변경 영역:
  - Swift Package `SpectraChatSDK` 생성
  - room list/create, history, read cursor, media read URL client 구현
  - `message.send`와 `read_cursor.update` command envelope helper 추가
  - SwiftPM CI, README, HANDOFF, integration guide와 release checklist 추가
- 검증 상태: `swift package resolve`, `swift package describe`, `swift test` 6 tests, workflow YAML parse, `git diff --check` 통과
- 상세 기록: [`docs/work-logs/2026-07-24-01-chat-sdk-rest-first-swiftpm-bootstrap.md`](docs/work-logs/2026-07-24-01-chat-sdk-rest-first-swiftpm-bootstrap.md)
