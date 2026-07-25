# 2026-07-25 — SDK-owned WebSocket realtime runtime

## 작업 목적과 이해한 내용

사용자는 ChatSDK가 실제 WebSocket 연결을 소유해야 SDK 소비자가 간편하게 개발할 수 있다고 확정했다. 기존 SDK는 REST API와 authenticated socket request, command envelope까지만 제공했고, 실제 `URLSessionWebSocketTask` 연결·receive loop·reconnect·event stream은 Spectra 앱 내부 구현이 담당했다.

## 문제 진단 또는 기존 동작

- `SpectraChatClient.socketRequest()`는 `/v1/socket` 인증 request만 만들었다.
- 앱은 별도 `URLSessionChatSocketClient`로 WebSocket 연결과 event stream을 관리했다.
- 이 구조는 SDK 사용자가 앱마다 WebSocket transport를 다시 만들어야 하므로 Platform SDK 목표와 맞지 않았다.

## 적용한 내용과 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
  - `SpectraChatRealtimeClient`를 추가했다.
  - SDK 내부에서 `URLSessionWebSocketTask`를 생성하고 `connect()` / `disconnect()` / receive loop를 소유한다.
  - `events()`로 `AsyncStream<SpectraChatRealtimeEvent>`를 제공한다.
  - `sendTextMessage`, generic `sendMessage`, `setTyping`, `updateReadCursor`, generic command send를 제공한다.
  - `message.created`, `read_cursor.updated`, `typing.updated`, server error와 call lifecycle event decode를 추가했다.
  - 기본 reconnect 상태 이벤트를 제공한다.
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
  - typing command와 realtime event decode 회귀 테스트를 추가했다.
- `README.md`, `HANDOFF.md`, `WORKLOG.md`
  - WebSocket runtime 소유권을 SDK로 갱신했다.

## 실행한 검증과 결과

- `swift test`
  - 15 tests 통과

## 남은 작업, 미검증 항목 또는 주의사항

- 실제 네트워크 WebSocket 연결과 reconnect UX는 앱 통합 후 `chat.spectra.kr` 또는 로컬 Chat endpoint에서 E2E 검증해야 한다.
- Spectra 앱의 기존 `URLSessionChatSocketClient`는 아직 교체되지 않았다. 앱 feature flag와 함께 `SpectraChatRealtimeClient`로 옮기는 후속 작업이 필요하다.
- Chat socket은 Call lifecycle reference만 전달한다. WebRTC SDP/ICE, LiveKit participant token, TURN credential과 provider secret은 계속 CallSDK/Call API가 소유한다.

## 커밋 기록

- 예정: `feat: add SDK-owned chat realtime socket`
