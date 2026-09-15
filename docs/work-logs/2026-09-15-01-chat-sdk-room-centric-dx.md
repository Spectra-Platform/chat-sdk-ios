# Modo Camp room-centric Chat SDK DX

## 작업 목적

Modo Camp iOS가 ChatSDK를 raw WebSocket wrapper가 아니라 Chat realtime platform layer로 사용할 수 있게 한다. 앱은 AuthSDK 객체를 주입하고 room 중심 API를 호출하며, ChatSDK가 `.chat` service token 발급/refresh, websocket-ticket 연결, reconnect와 subscribed-room event filtering을 맡는다.

## 기존 동작

- 기존 `SpectraChatAccessTokenProviding` 주입 경로는 있었지만 앱 개발자가 Chat service token provider를 직접 만들어야 했다.
- `SpectraChatRealtimeClient.connect(roomID:)`는 roomID를 받지만 실제로는 사용하지 않았고, `/v1/socket` bearer 연결 helper가 남아 있었다.
- 서버의 현재 WebSocket 계약은 `POST /v1/chat/rooms/{room_id}/websocket-ticket` 후 `/v1/socket?ticket=...` 연결이다. `/v1/socket` bearer fallback은 서버 README/HANDOFF 기준으로 허용되지 않는다.
- 일부 realtime decoder는 roomID가 없을 때 빈 문자열 또는 `conversation_id`를 roomID처럼 대체했다.

## 적용 내용

- `Package.swift`에 AuthSDK `0.1.2` dependency를 추가하고, AuthSDK minimum platform에 맞춰 ChatSDK minimum platform을 iOS 17/macOS 14로 조정했다.
- `SpectraChatAuthServiceTokenProvider`와 `SpectraChatClient(auth:)`를 추가해 AuthSDK `ServiceTokenProvider`에서 `.chat` service token을 SDK 내부에서 요청한다.
- `SpectraChatClient`에 `getRoom(roomID:)`, `SpectraChatRoom.id`, `sendMessage(roomID:text:)`, `markRead(roomID:sequence:)`, `connect()`, `subscribe(roomID:)`, `connect(roomID:)`, `setTyping(roomID:isTyping:)`, `events()`를 추가했다.
- `SpectraChatRealtimeClient.subscribe(roomID:)`가 room websocket ticket을 발급받고 `/v1/socket?ticket=...`으로 연결하도록 바꿨다. reconnect는 새 ticket을 받는다.
- subscribed roomID와 맞는 room event만 delegate/stream으로 전달하도록 event filtering을 추가했다.
- `ROOM_ID_REQUIRED` 오류를 추가하고, roomID가 필요한 REST/realtime path에서 빈 roomID를 SDK 단계에서 거절한다.
- call lifecycle decoder는 `conversation_id`를 roomID fallback으로 사용하지 않는다. 실제 `room_id` 또는 `call.chat_room_id`가 없으면 `ROOM_ID_REQUIRED`를 반환한다.
- `SpectraChatClientDelegate`, `SpectraChatLogger`, `SpectraChatLogLevel`과 safe log field 생성을 추가했다. token, ticket, signed URL, raw message text, raw file name은 logger fields에 넣지 않는다.
- README, HANDOFF, WORKLOG, integration guide, release checklist, Modo parity guide를 갱신했다.

## 검증

- `swift test`: 40 tests 통과
- 추가된 회귀:
  - Auth object token provider가 `.chat` service token을 요청
  - roomID required failure와 conversationID fallback 금지
  - websocket-ticket request와 ticket query socket request
  - logger redaction
  - subscribed-room event filtering
- `git diff --check`: 통과

## 서버 변경 필요 여부

- 현재 SDK 구현은 서버의 기존 `POST /v1/chat/rooms/{room_id}/websocket-ticket` 계약을 사용한다. subscribe/connect를 위해 새 서버 endpoint는 필요하지 않다.
- `getRoom(roomID:)`는 서버에 `GET /v1/chat/rooms/{room_id}`가 없어 `listRooms()` 결과에서 찾는 compatibility helper다. 단일 room lookup을 자주 호출하거나 room list가 커지면 Chat 서버에 dedicated endpoint가 필요하다.
- Direct room 생성의 same-pair idempotency는 현재 서버 계약에 명시되어 있지 않다. Modo Camp가 같은 user pair에 항상 같은 room을 요구하면 서버 계약과 테스트를 추가해야 한다.

## 남은 작업

- 실제 Modo Camp iOS 앱에서 AuthSDK hosted session으로 `.chat` token 발급, room 생성, websocket-ticket, subscribe, send/read/typing 흐름을 Live/Test 사용자 세션으로 검증해야 한다.
- Mini PC/public `chat.spectra.kr`에서 Auth service token issuance부터 Chat REST/websocket-ticket/socket reconnect까지 E2E smoke가 필요하다.
- SwiftPM release tag는 만들지 않았다. AuthSDK dependency와 minimum platform 변경이 포함되므로 후보 버전은 `v0.2.0`이 적절하다.
