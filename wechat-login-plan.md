# 微信登录接入方案

## Context

当前项目「康源华善」(KYHSApp) 只支持用户名/密码登录，需要接入微信登录。用户已有微信 AppID，后端已有微信登录接口。项目目前无任何第三方依赖管理器，需要从零引入 CocoaPods 和微信 SDK。

---

## 实现进度

| 步骤 | 状态 | 说明 |
|------|------|------|
| 1. 初始化 CocoaPods 并添加微信 SDK | ❌ 未开始 | |
| 2. 新建 AppDelegate（WeChat SDK 生命周期） | ❌ 未开始 | |
| 3. 在 KYHSAppApp.swift 中接入 AppDelegate | ❌ 未开始 | |
| 4. 配置 Info.plist | ❌ 未开始 | |
| 5. 新建 WeChatLoginManager | ❌ 未开始 | |
| 6. AuthManager 添加微信登录方法 | ❌ 未开始 | |
| 7. LoginView 添加微信登录按钮 | ✅ 已完成 | 见下方详情 |

### 步骤 7 完成详情（2026-05-19）

已完成 LoginView 微信登录按钮的 UI 部分：

- **`LoginView.swift`** — 在协议勾选下方添加了"其他登录方式"分隔线 + 微信登录按钮（微信绿 `#07C160`）
- **`wechat-icon.imageset/`** — 新建了微信图标资源（1x/2x/3x 白色图标，用于绿色按钮上）
- **`handleWeChatLogin()`** — 方法已添加，目前暂显示"微信登录功能开发中"提示，等 SDK 接入后替换为 `WeChatLoginManager.shared.requestLogin()`

下一步：完成步骤 1-6（CocoaPods + SDK 接入 + 实际登录逻辑）

---

## 实现步骤

### 1. 初始化 CocoaPods 并添加微信 SDK

**新建** `KYHSApp/Podfile`：

```ruby
platform :ios, '18.0'
target 'KYHSApp' do
  use_frameworks!
  pod 'WechatOpenSDK-XCFramework'
end
```

- `use_frameworks!` 让纯 Swift 项目可以直接 `import WXApi`，无需桥接头文件
- 运行 `pod install` 后，改用 `KYHSApp.xcworkspace` 打开项目

**修改** `.gitignore`：添加 `Pods/`

### 2. 新建 AppDelegate（WeChat SDK 生命周期）

**新建** `KYHSApp/KYHSApp/Services/AppDelegate.swift`：

- 继承 `NSObject`，遵循 `UIApplicationDelegate` + `WXApiDelegate`
- `didFinishLaunchingWithOptions` 中调用 `WXApi.registerApp(appID, universalLink:)`
- `application(_:open:options:)` 中调用 `WXApi.handleOpenURL(_:delegate:)`
- `onResp(_:)` 中接收 `SendAuthResp`，将 auth code 转发给 `WeChatLoginManager`

### 3. 在 KYHSAppApp.swift 中接入 AppDelegate

**修改** `KYHSApp/KYHSApp/KYHSAppApp.swift`：

添加一行：`@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate`

### 4. 配置 Info.plist

**修改** `KYHSApp/KYHSApp/Info.plist`：

- 添加 `CFBundleURLTypes`：URL Scheme 为 `wx{AppID}`
- 添加 `LSApplicationQueriesSchemes`：`weixin`、`weixinULAPI`

### 5. 新建 WeChatLoginManager

**新建** `KYHSApp/KYHSApp/Services/WeChatLoginManager.swift`：

- 单例 `WeChatLoginManager.shared`
- `isWeChatInstalled` — 检查微信是否安装
- `requestLogin()` — 构造 `SendAuthReq`（scope: `snsapi_userinfo`），调用 `WXApi.send()`
- `handleAuthResponse(_:)` — 处理微信回调，成功时提取 code 调用 `AuthManager.shared.loginWithWeChat(code:)`

### 6. AuthManager 添加微信登录方法

**修改** `KYHSApp/KYHSApp/Services/AuthManager.swift`：

添加 `loginWithWeChat(code:)` 方法：
- 调用后端接口 `POST /sysUser/appLogin`（代码中已存在的接口），参数 `{ "code": code }`
- 复用现有 `LoginResponse` 模型解析 token 和 userId
- 成功后调用现有的 `login(token:userId:)` + `fetchUserInfo()`，无需重复认证逻辑

### 7. LoginView 添加微信登录按钮 ✅

**修改** `KYHSApp/KYHSApp/Views/Login/LoginView.swift`：

- ~~添加 `@StateObject private var weChatManager = WeChatLoginManager.shared`~~（等 SDK 接入后添加）
- ✅ 在协议勾选下方添加分隔线 + 微信登录按钮（微信绿 `#07C160`）
- ✅ `handleWeChatLogin()` 方法：先检查协议同意，暂显示开发中提示
- 🔲 监听 `weChatManager.weChatError` 显示错误提示（等 WeChatLoginManager 创建后添加）

---

## 文件变更汇总

| 文件 | 操作 | 说明 | 状态 |
|------|------|------|------|
| `KYHSApp/Podfile` | 新建 | CocoaPods 配置 | ❌ |
| `KYHSApp/KYHSApp/Services/AppDelegate.swift` | 新建 | AppDelegate + WXApiDelegate | ❌ |
| `KYHSApp/KYHSApp/Services/WeChatLoginManager.swift` | 新建 | 微信登录流程管理 | ❌ |
| `KYHSApp/KYHSApp/KYHSAppApp.swift` | 修改 | 添加 AppDelegateAdaptor | ❌ |
| `KYHSApp/KYHSApp/Info.plist` | 修改 | URL Scheme + Query Schemes | ❌ |
| `KYHSApp/KYHSApp/Views/Login/LoginView.swift` | 修改 | 微信登录按钮 | ✅ |
| `KYHSApp/KYHSApp/Services/AuthManager.swift` | 修改 | 添加 loginWithWeChat 方法 | ❌ |
| `.gitignore` | 修改 | 添加 Pods/ | ❌ |

---

## 已确认的参数

| 参数 | 值 |
|------|------|
| Bundle ID | `cn.kangyuanhuashan.app` |
| Universal Link | `https://api.kangyuanhuashan.cn/app/` |
| 后端微信登录接口 | `POST /sysUser/appLogin`（代码中已存在） |
| 微信 AppID | 待微信开放平台审核通过后获取 |

## 需要后端配合的事项

在 `https://api.kangyuanhuashan.cn/.well-known/apple-app-site-association` 部署配置文件（无 `.json` 后缀，Content-Type: `application/json`）：

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TeamID>.cn.kangyuanhuashan.app",
        "paths": [ "/app/*" ]
      }
    ]
  }
}
```

`<TeamID>` 需替换为 Apple Developer 账号的 Team ID。

## 验证方式

1. `pod install` 成功，项目可编译
2. 点击微信登录按钮 → 跳转微信授权页
3. 授权后 → 回到 App → 自动登录成功进入主页
4. 模拟器上微信按钮不可用或提示安装微信
5. 取消授权时无异常提示
