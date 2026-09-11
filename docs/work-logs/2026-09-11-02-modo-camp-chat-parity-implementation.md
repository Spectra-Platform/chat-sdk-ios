# Modo Camp Chat parity implementation

## 작업 목적과 이해한 내용

Modo Camp iOS SwiftUI 앱이 JS `@spectra-platform/chat-sdk@0.2.0`과 같은 의미로
Spectra Chat room, message, attachment, realtime, membership 기능을 호출할 수 있도록
`chat-sdk-ios` public API를 보강한다.

Modo backend conversation은 계속 최종 authority다. Spectra realtime event는 Modo 앱에서
conversation refetch 또는 invalidation trigger로만 사용한다.

## 문제 진단 또는 기존 동작

- iOS SDK에는 REST room/message/read API와 WebSocket runtime은 있었지만 JS parity naming 일부가 달랐다.
- `POST /v1/chat/rooms/{roomId}/leave`, `GET /v1/chat/rooms/{roomId}/membership` public API가 없었다.
- `room.membership.updated` control event가 Swift public event로 노출되지 않았다.
- Storage attachment helper는 있었지만 JS `uploadFiles()`/`sendMessageWithFiles()`와 같은 app-facing API는 없었다.

## 적용한 내용과 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
  - `createDirectRoom(userID:)`, `createGroupRoom(title:userIDs:)`, `sendMessage(roomID:options:)`,
    `markRead(roomID:lastReadSequence:)` parity alias를 추가했다.
  - `SpectraChatMembershipRequestOptions`, `SpectraChatRoomMembership`,
    `SpectraChatLeaveRoomResult`를 추가하고 leave/membership REST API를 구현했다.
  - membership API의 기본 10초 deadline을 추가했다. deadline은 token acquisition, HTTP request,
    response parsing을 포함한다. task cancellation은 `REQUEST_ABORTED`, timeout은 `REQUEST_TIMEOUT`으로 노출한다.
  - `SpectraChatError`에 `code`, `status`, `message`, `requestID`, `retryable` 접근자를 추가했다.
  - `SpectraChatFileDescriptor`, `SpectraChatUploadFilesOptions`,
    `SpectraChatSendMessageWithFilesOptions`와 StorageSDK bridge를 추가했다.
  - `room.membership.updated` decode, legacy `.membership`, JS-style `SpectraChatEvent`와
    `eventStream()`을 추가했다.
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
  - JS naming alias, send options, leave/membership path, deadline, file upload bridge,
    send-with-files, membership event와 `SpectraChatEvent` decode unit test를 추가했다.
- `README.md`, `HANDOFF.md`, `docs/guides/modo-camp-ios-chat-parity.md`, `WORKLOG.md`
  - public API, JS mapping, Modo authority rule, 남은 검증 범위를 현재 구현 상태로 갱신했다.

## 실행한 검증과 결과

- `swift test`
  - 결과: 통과
  - 범위: 35 tests
- `git diff --check`
  - 결과: 통과

## 남은 작업, 미검증 항목 또는 주의사항

- Modo Camp iOS SwiftUI 앱에 실제 SPM pin을 반영하고 UI flow에서 적용하는 작업은 별도 소비 앱 범위다.
- 실제 Live 사용자 bearer/session으로 leave 후 `listMessages`, `sendMessage`, `setTyping`,
  websocket ticket 차단과 남은 참가자 history 유지 E2E는 미검증이다.
- 실제 iPhone/Simulator에서 파일 picker, 큰 파일 업로드, background/foreground 전환,
  reconnect/refetch UX는 미검증이다.
- StorageSDK bridge는 주입된 `SpectraStorageClient`가 필요하다. ChatSDK는 storage token을 직접 만들지 않는다.
