# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project

康源华善 (KYHSApp) — a SwiftUI iOS app for shop owners (店长) covering live-streaming center, video quizzes, and a user center with QR-code clock-in. Bundle ID `cn.kangyuanhuashan.app`, Swift 5, iOS 15.6 deployment target. UI strings are Chinese (zh_CN).

The Xcode workspace lives at `KYHSApp/KYHSApp.xcworkspace`; use it instead of opening the project directly because the app uses CocoaPods for `WechatOpenSDK-XCFramework`.

## Build / run

Open `KYHSApp/KYHSApp.xcworkspace` in Xcode and run on a simulator or device. From the CLI:

```bash
# Build for simulator
xcodebuild -workspace KYHSApp/KYHSApp.xcworkspace -scheme KYHSApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

There is no test target and no linter/formatter wired in. Don't claim build success from compile alone for UI changes — exercise the affected screen in the simulator.

## Architecture

Entry point `KYHSApp/KYHSApp/KYHSAppApp.swift` switches the root scene between `LoginView` and `MainTabView` based on `AuthManager.shared.isAuthenticated`. `MainTabView` hosts three tabs: `LiveCenterView`, `VideoQuizListView`, `UserCenterView`.

State is held in views with `@State` / `@StateObject`; the only app-wide store is `AuthManager` (`@MainActor` singleton, `ObservableObject`) injected as `EnvironmentObject`. There is no separate view-model layer — views call `NetworkService.shared` directly inside `Task { ... }`.

### Networking — read this before editing API calls

`Services/NetworkService.swift` is the only HTTP client. Two base URLs:

- `baseURL = https://api.kangyuanhuashan.cn` — main API.
- `videoBaseURL = http://116.132.104.106:31000` — video CDN. `Info.plist` sets `NSAllowsArbitraryLoads=true` to permit HTTP. Use `NetworkService.shared.spliceVideoURL(_:)` to build full video URLs from relative paths returned by the API.

Auth header is **`token`**, not `Authorization: Bearer …`. The token is loaded from Keychain on every request unless `ignoreToken: true` is passed.

Response envelope is `{ code, msg, data }`. The decoder unwraps `data` and decodes only that field into `T` when `code == 200`. Important consequences:

- A successful endpoint that returns no `data` → declare the call site's `T` as `EmptyResponse`. The decoder returns an `EmptyResponse()` for empty strings / `null` / non-dict-non-array values.
- `code == 401` triggers `AuthManager.shared.logout()` and throws `.unauthorized`, **except** for `/sysUser/appLogin` (which uses 401 as part of its own protocol).
- Non-200 codes throw `.serverError(msg)`.

Default `Content-Type` is `application/x-www-form-urlencoded` (form-encoded via JSON round-trip in `formEncode`). Pass `contentType: "application/json"` when an endpoint expects JSON (e.g. `/videoQuiz/submitAnswer`). The path `/upload/uploadFile` is a special case that skips setting Content-Type so multipart boundaries survive.

### Auth & storage

`AuthManager` owns `isAuthenticated` and cached `userInfo`. Token + userId go to Keychain via `KeychainManager` (service `cn.kangyuanhuashan.app`, `kSecAttrAccessibleAfterFirstUnlock`). Cached `userInfo` lives in `UserDefaults` under `cachedUserInfo`. `logout()` clears both.

`CryptoUtils.md5` is a hand-rolled MD5 (no CommonCrypto import) — keep it; some legacy login flows depend on it.

### Adding a screen

Place SwiftUI views under `Views/<Feature>/`, register them in `KYHSApp.xcodeproj/project.pbxproj` (no auto file discovery). Follow the existing pattern: `NavigationStack` + `ZStack` background + `.toast($toastItem)` for transient messages (`Views/Common/ToastModifier.swift`). The brand green is `#0A9200` / gradient `#0AB00A → #0A9200`; `Color(hex:)` is defined at the bottom of `LoginView.swift`.

### Adding a model

All Codable DTOs live in `Models/Models.swift` as one flat file. Match the server's snake_case field names directly (e.g. `live_status`, `videoM3u8Url`) — there is no global `keyDecodingStrategy`, so renames break decoding silently.

## Conventions worth preserving

- Network calls log emoji-prefixed lines (🔑 🌐 📡 📦) on purpose for field debugging — keep the style when adding new logging in `NetworkService`.
- `AuthManager` is `@MainActor`; when calling `logout()` from a background context, hop with `await MainActor.run { … }` (the network layer already does this on 401).
- The login form requires the user to tick the agreement checkbox; the existing `pendingLoginAction` pattern in `LoginView` defers the action until they accept in the alert. Reuse it for any new login method (the WeChat button already does).
