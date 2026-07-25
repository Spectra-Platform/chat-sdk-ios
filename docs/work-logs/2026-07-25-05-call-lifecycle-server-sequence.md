# 2026-07-25 — Call lifecycle server sequence exposure

## 작업 목적과 이해한 내용

Spectra 앱이 ChatSDK-owned WebSocket runtime을 실제 socket adapter로 사용할 때, Call lifecycle event의 ordering과 재연결 gap 복구 cursor가 필요하다. 기존 `SpectraChatCallLifecycleEvent`는 `call.*` event를 decode하지만 `server_sequence`를 public model에 노출하지 않아 앱 consumer가 기존 native socket과 같은 cursor 경계를 유지하기 어려웠다.

## 문제 진단 또는 기존 동작

- `SpectraChatRealtimeClient`는 `call.invited`, `call.accepted`, `call.declined`, `call.joined`, `call.left`, `call.ended`, `call.missed`를 `SpectraChatCallLifecycleEvent`로 decode한다.
- message/read cursor/typing event는 필요한 room/user/sequence 값을 갖고 있었지만, call lifecycle public model에는 envelope의 `server_sequence`가 빠져 있었다.
- 앱의 `RemoteVideoCallCoordinationRepository`는 `serverSequence`를 cursor로 사용해 at-least-once event 중복과 reconnect recovery를 다룬다.

## 적용한 내용과 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
  - `SpectraChatCallLifecycleEvent.serverSequence`를 추가했다.
  - `server_sequence`를 optional decode하고 누락 시 `0`으로 fallback한다.
  - public initializer에도 `serverSequence` 기본값을 추가했다.
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
  - plural participant call fixture와 singular participant call fixture 모두 `server_sequence` decode를 확인한다.
- `HANDOFF.md`, `WORKLOG.md`
  - 앱 consumer가 `serverSequence`를 reconnect cursor에 사용할 수 있는 기준을 기록했다.

## 실행한 검증과 결과

- `swift test`
  - 15 tests 통과
- `git diff --check`
  - 통과

## 남은 작업, 미검증 항목 또는 주의사항

- 실제 WebSocket 네트워크 연결과 reconnect ordering은 앱 adapter 통합 뒤 E2E로 검증해야 한다.
- `server_sequence`가 없는 legacy event는 `0`으로 fallback하므로 consumer는 event ID 중복 제거를 함께 유지해야 한다.

## 커밋 기록

- `f66de48 feat: expose call lifecycle server sequence`
