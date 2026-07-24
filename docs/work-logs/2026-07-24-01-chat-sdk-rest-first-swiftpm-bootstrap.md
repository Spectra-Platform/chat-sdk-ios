# 2026-07-24 — ChatSDK REST first SwiftPM bootstrap

## 작업 목적

`chat-sdk-ios`를 실제 앱에서 Swift Package Manager Git URL로 붙일 수 있는 첫 iOS SDK로 부트스트랩한다.

## 기존 상태

- `https://github.com/Spectra-Platform/chat-sdk-ios.git` 원격 repo는 존재했지만 비어 있었다.
- `spectra-chat`에는 REST room/history/read cursor/media URL과 WebSocket command 계약이 구현되어 있었다.
- iOS SDK repo, Swift Package, 문서, CI와 테스트는 아직 없었다.

## 적용 내용

- Swift Package `SpectraChatSDK`를 생성했다.
- AuthSDK hard dependency 없이 `SpectraChatAccessTokenProviding` protocol을 추가했다.
- REST room list/create, message history, read cursor, media read URL client를 구현했다.
- WebSocket `message.send`, `read_cursor.update` command envelope helper와 socket URL derivation을 추가했다.
- Chat error response decode를 추가했다.
- README, HANDOFF, integration guide, release checklist와 SwiftPM CI를 추가했다.

## 주요 변경 파일

- `Package.swift`
- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
- `.github/workflows/ci.yml`
- `README.md`
- `HANDOFF.md`
- `WORKLOG.md`
- `docs/guides/ios-chat-sdk-integration.md`
- `docs/guides/release-checklist.md`

## 검증

- `swift package resolve`
- `swift package describe`
- `swift test`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml")'`
- `git diff --check`

## 남은 작업

- URLSessionWebSocketTask 기반 reconnect/runtime transport를 추가한다.
- server event typed decoder convenience를 추가한다.
- 실제 Spectra iOS 앱에 ChatSDK를 연결한다.
- 실제 message send → Chat outbox → Notification push 수신 E2E를 확인한다.

## 커밋 기록

- 이번 작업 커밋에서 기록한다.
