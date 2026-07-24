# 2026-07-25 — Call lifecycle event decoder for Chat socket

## 작업 목적

Call Platform을 별도 media 서버로 두되, 통화 초대·수락·종료 같은 durable lifecycle fan-out은 Chat socket을 사용한다. iOS ChatSDK는 이 이벤트를 안전하게 decode해 앱과 CallKit/CallSDK integration이 사용할 수 있게 해야 한다.

## 기존 상태

- ChatSDK는 authenticated socket request와 `message.send`, `read_cursor.update` command envelope까지만 제공했다.
- 영상통화 관련 socket event는 앱 구현에 남아 있었고, 새 Platform Chat SDK public surface에는 call lifecycle decoder가 없었다.
- Chat socket이 media credential을 싣지 않는다는 경계가 SDK 문서에 명시되지 않았다.

## 적용 내용

- `SpectraChatCallEventType`을 추가해 `call.invited`, `call.accepted`, `call.declined`, `call.joined`, `call.left`, `call.ended`, `call.missed`를 표현했다.
- `SpectraChatCallLifecycleEvent`와 actor, call summary, participant, trace payload 타입을 추가했다.
- `participants` 배열과 단일 `participant` payload를 모두 decode해 direct와 group event를 같은 구조로 소비할 수 있게 했다.
- `carriesMediaTransportCredential == false` 경계를 public surface에 두고, WebRTC SDP/ICE, LiveKit participant token, TURN credential과 provider secret은 Call API/CallSDK 소유임을 문서화했다.

## 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
- `README.md`
- `HANDOFF.md`
- `WORKLOG.md`

## 검증

- `swift test` — 10 tests 통과
- `git diff --check` — 통과

## 남은 작업

- URLSessionWebSocketTask 기반 runtime transport와 reconnect helper는 후속 slice다.
- `message.created`, `read_cursor.updated`, `typing.updated` 같은 non-call server event decoder는 아직 미구현이다.
- 실제 Chat Platform socket producer와 iOS 앱 CallKit/LiveKit E2E는 별도 저장소 연동 후 검증해야 한다.

## 커밋 기록

- `8d4e467` — `feat: decode call lifecycle chat events`
