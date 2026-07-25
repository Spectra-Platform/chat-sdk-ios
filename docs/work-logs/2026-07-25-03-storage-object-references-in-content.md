# 2026-07-25 — Storage object references in received content

## 작업 목적과 이해

- Spectra 앱에서 채팅 이미지, 파일 첨부와 음성 녹음을 StorageSDK로 업로드한 뒤 ChatSDK message send에 `storage_object_references`로 넘기는 흐름이 필요하다.
- ChatSDK `v0.1.0`은 송신 payload에는 `SpectraChatStorageObjectReference`를 보낼 수 있었지만, history/send 응답의 `SpectraChatContent`에는 같은 필드를 노출하지 않았다.
- 앱이 StorageSDK 기반 첨부 메시지를 보존·표시하려면 ChatSDK가 수신 content에서도 storage reference를 decode해야 한다.

## 문제 진단

- `SpectraChatSendContent`에는 `storageObjectReferences`가 있었다.
- `SpectraChatContent`는 `kind`, `text`, `mediaItems`만 가지고 있어, 서버가 `storage_object_references`를 반환해도 SDK consumer가 접근할 수 없었다.
- StorageSDK에 직접 의존하지 않는 ChatSDK의 기존 경계는 유지해야 한다.

## 적용한 내용

- `SpectraChatContent.storageObjectReferences` optional 필드를 추가했다.
- `storage_object_references` coding key를 추가했다.
- history 응답에서 object key, content type, byte size, checksum, metadata를 보존하는 회귀 테스트를 추가했다.
- `HANDOFF.md`와 `WORKLOG.md`에 수신 content의 storage reference 보존 결정을 기록했다.

## 주요 변경 파일

- `Sources/SpectraChatSDK/SpectraChatSDK.swift`
- `Tests/SpectraChatSDKTests/SpectraChatClientTests.swift`
- `HANDOFF.md`
- `WORKLOG.md`

## 검증

- `swift test` — 11 tests 통과
- `git diff --check` — 통과

## 남은 작업과 미검증 항목

- Spectra 앱에서 StorageSDK upload 결과를 `SpectraChatStorageObjectReference`로 변환해 `sendMessage`에 전달해야 한다.
- Chat Platform 서버가 production runtime에서 storage reference attachment를 저장·반환하는지는 live E2E가 필요하다.
- 실제 이미지/파일/음성 첨부 메시지의 iOS 화면 표시와 다운로드 URL resolve는 Spectra 앱 통합 slice에서 검증해야 한다.
