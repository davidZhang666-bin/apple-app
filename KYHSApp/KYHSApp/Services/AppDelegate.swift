import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#elseif canImport(WXApi)
import WXApi
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(WechatOpenSDK) || canImport(WXApi)
        WXApi.registerApp(
            WeChatLoginConfig.appID,
            universalLink: WeChatLoginConfig.universalLink
        )
        #endif
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        #if canImport(WechatOpenSDK) || canImport(WXApi)
        return WXApi.handleOpen(url, delegate: self)
        #else
        return false
        #endif
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        #if canImport(WechatOpenSDK) || canImport(WXApi)
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        #else
        return false
        #endif
    }
}

#if canImport(WechatOpenSDK) || canImport(WXApi)
extension AppDelegate: WXApiDelegate {
    func onResp(_ resp: BaseResp) {
        guard let authResponse = resp as? SendAuthResp else { return }
        Task { @MainActor in
            WeChatLoginManager.shared.handleAuthResponse(authResponse)
        }
    }
}
#endif
