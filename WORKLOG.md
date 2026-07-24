# WORKLOG — chat-sdk-ios

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
