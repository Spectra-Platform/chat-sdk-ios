# HANDOFF — chat-sdk-ios

## 목적과 소유 범위

`chat-sdk-ios`는 Spectra Chat의 iOS 공개 SDK를 소유한다. 앱이 Auth token provider를 주입하고 Chat REST API와 WebSocket command envelope를 안전하게 사용할 수 있게 한다.

이 저장소는 iOS SDK만 소유한다. Chat 서버, PostgreSQL, NATS/JetStream, Notification consumer, 앱 화면과 운영 배포는 각각 해당 저장소의 소유 범위다.

## 확정된 결정

- iOS 앱 bundle에는 internal service key, Chat DB credential, NATS credential, Notification provider credential을 넣지 않는다.
- SDK는 AuthSDK에 hard dependency를 두지 않고 `SpectraChatAccessTokenProviding` protocol을 주입받는다.
- REST history와 room list는 PostgreSQL source of truth를 조회하는 public Chat API를 사용한다.
- WebSocket 실시간 전송은 `/v1/socket`과 `message.send`, `read_cursor.update` command envelope를 따른다.
- ChatSDK는 push notification을 직접 발송하지 않는다. message transaction 뒤 수신자별 notification request outbox와 Notification consumer가 담당한다.
- Swift Package Manager 배포는 Git URL 기반으로 시작한다. repository URL은 `https://github.com/Spectra-Platform/chat-sdk-ios.git`, product 이름은 `SpectraChatSDK`다.
- release tag는 `vMAJOR.MINOR.PATCH` 형식으로 만들며, 최초 tag는 공개 버전 번호를 확정한 뒤 생성한다.

## 현재 구현 경계

- Swift Package `SpectraChatSDK`가 생성됐다.
- `.github/workflows/ci.yml`이 SwiftPM resolve/describe/test를 검증한다.
- Public surface:
  - `SpectraChatClientConfiguration`
  - `SpectraChatAccessTokenProviding`
  - `StaticSpectraChatAccessTokenProvider`
  - `SpectraChatClient`
  - `SpectraChatRoom`
  - `SpectraChatMessage`
  - `SpectraChatContent`
  - `SpectraChatSendContent`
  - `SpectraChatMediaItem`
  - `SpectraChatMediaReadURL`
  - `SpectraChatCommandEnvelope`
  - `SpectraChatSendMessage`
  - `SpectraChatReadCursorUpdate`
  - `SpectraChatError`
- Unit test는 bearer header, REST path/query/body, history decode, media read URL, command envelope와 error decode를 검증한다.
- iOS 앱 통합 기준 문서는 `docs/guides/ios-chat-sdk-integration.md`에 둔다.
- SwiftPM 릴리즈 기준은 `docs/guides/release-checklist.md`에 둔다.

## 변경 시 함께 확인할 계약·저장소

- `spectra-chat`: REST/WebSocket producer, message/history/outbox
- `Spectra-Platform/auth-sdk-ios`: app user token provider adapter
- `Spectra-Platform/notification-sdk-ios`: APNs device registration과 push deep link
- `spectra-notification` 또는 `Spectra-Platform/delivery-platform`: message push consumer
- `spectra-ios`: chat 화면, WebSocket runtime, foreground sound/banner suppression

## 남은 작업과 미확정 항목

- URLSessionWebSocketTask 기반 reconnect/runtime transport
- server event decoding convenience
- rich media upload flow와 Media/Storage SDK 연결
- 실제 Spectra iOS 앱 integration
- 실제 message send → Notification push 기기 수신 E2E

## 마지막으로 코드와 대조한 날짜

- 2026-07-24
