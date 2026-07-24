# ChatSDK iOS Release Checklist

이 문서는 `chat-sdk-ios`를 Swift Package Manager로 배포할 때 확인할 기준이다.

## 배포 단위

- Repository: `https://github.com/Spectra-Platform/chat-sdk-ios.git`
- Swift package name: `SpectraChatSDK`
- Library product: `SpectraChatSDK`
- Minimum platform: iOS 15, macOS 12
- Swift tools version: 5.9

## 앱에서 추가하는 방법

```swift
.package(
    url: "https://github.com/Spectra-Platform/chat-sdk-ios.git",
    .upToNextMinor(from: "0.1.0")
)
```

product:

```swift
.product(name: "SpectraChatSDK", package: "chat-sdk-ios")
```

## 버전 정책

- tag는 `vMAJOR.MINOR.PATCH` 형식을 사용한다. 예: `v0.1.0`
- `0.x` 구간에서는 public API 변경이 잦을 수 있으므로 앱은 `.upToNextMinor` 또는 exact version을 우선 사용한다.
- internal service key, NATS credential, DB credential, APNs/FCM provider credential은 tag에 포함하지 않는다.

## 릴리즈 전 로컬 검증

```bash
swift package resolve
swift package describe
swift test
git diff --check
```

CI도 같은 범위를 검증한다.

## tag 생성 절차

```bash
git status --short
git tag -a v0.1.0 -m "ChatSDK iOS 0.1.0"
git push origin v0.1.0
```

## 현재 배포 경계

이 체크리스트는 SwiftPM package 배포 가능 상태를 다룬다. 아직 다음 항목은 구현 완료가 아니다.

- WebSocket reconnect/runtime transport
- server event typed decoder convenience
- rich media upload와 Media/Storage SDK 연결
- 실제 Spectra iOS app integration
- 실제 message send → Notification push 기기 수신 E2E
