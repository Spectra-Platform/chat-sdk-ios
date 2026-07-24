# WORKLOG — chat-sdk-ios

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
