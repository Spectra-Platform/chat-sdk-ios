# WORKLOG — chat-sdk-ios

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
