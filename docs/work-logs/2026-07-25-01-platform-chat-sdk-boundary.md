# 2026-07-25 — Platform Chat SDK boundary refinement

## 작업 목적

새 Spectra Platform 기준의 Chat SDK 첫 사용 표면을 보강한다. iOS 앱은 AuthSDK에서 받은 app-user token provider를 ChatSDK에 주입하고, ChatSDK는 REST request와 WebSocket request에 bearer token을 붙인다.

## 기존 상태

- SwiftPM package와 기본 room/history/read cursor/media URL client는 이미 있었다.
- README에는 “기존 Chat REST 계약” 표현이 남아 있어 새 Platform Chat 경계가 덜 분명했다.
- public API에 REST `sendMessage`, `markRead` 별칭, authenticated WebSocket request helper, Storage attachment reference 타입이 없었다.

## 적용 내용

- `SpectraChatClientConfiguration.projectId`를 추가하고, 설정된 경우 request에 `X-Spectra-Project-Id`를 붙이게 했다.
- generic `createRoom(_:)`, REST `sendMessage(...)`, `markRead(...)`, `socketRequest()`를 public API로 추가했다.
- Storage SDK 직접 의존 없이 첨부 경계를 표현하는 `SpectraChatStorageObjectReference`를 추가했다.
- README, HANDOFF, iOS integration guide와 WORKLOG를 새 Platform Chat 기준으로 갱신했다.

## 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
- `README.md`
- `HANDOFF.md`
- `WORKLOG.md`
- `docs/guides/ios-chat-sdk-integration.md`

## 검증

- `swift test` — 8 tests 통과
- `git diff --check` — 통과

## 남은 작업

- Chat Platform producer API가 확정되면 REST path, error code, event schema를 최종 계약과 다시 대조한다.
- URLSessionWebSocketTask 기반 reconnect/runtime transport는 후속 slice로 구현한다.
- 실제 Spectra iOS 앱에 AuthSDK와 함께 로컬 package로 연결하고 message send → server outbox → push 수신 E2E를 확인한다.

## 커밋 기록

- `1881b11` — `feat: refine platform chat sdk boundary`
