# 2026-09-11 — Modo Camp Chat parity draft

## 작업 목적과 이해한 내용

Modo Camp iOS가 React 웹 `@spectra-platform/chat-sdk@0.2.0`과 같은 room,
message, attachment, realtime, membership 의미를 사용할 수 있도록 Swift
public API 목표와 authority 경계를 문서화했다.

## 문제 진단 또는 기존 동작

기존 `chat-sdk-ios`는 REST, WebSocket runtime, event decode, Storage attachment
helper를 구현했지만 JS `0.2.0`의 `leaveRoom`, `getRoomMembership`,
`membership` event, `uploadFiles`, `sendMessageWithFiles` app-facing parity는
아직 완전히 맞지 않는다.

## 적용한 내용과 주요 변경 파일

- `docs/guides/modo-camp-ios-chat-parity.md`
  - Swift Chat API 초안, membership timeout/cancel 경계, Modo backend authority
    원칙, diagnostics redaction과 JS parity checklist를 추가했다.
- `README.md`, `HANDOFF.md`, `WORKLOG.md`
  - Modo Camp parity guide와 미구현 경계를 연결했다.

## 실행한 검증과 결과

- 문서 변경만 수행했다. Swift code와 Package manifest는 변경하지 않았다.
- `git diff --check`로 whitespace 검증이 필요하다.

## 남은 작업, 미검증 항목 또는 주의사항

- `leaveRoom`, `getRoomMembership`, `membership` event를 Swift 코드와 테스트로
  구현해야 한다.
- `uploadFiles`, `sendMessageWithFiles`를 JS `0.2.0` naming과 input shape에 맞춘
  app-facing API로 정리해야 한다.
- 실제 Chat live socket, reconnect, server replay/gap recovery는 검증하지 않았다.
