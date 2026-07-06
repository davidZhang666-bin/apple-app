import Foundation
import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#elseif canImport(WXApi)
import WXApi
#endif

enum WeChatLoginConfig {
    static let appID = "wxbe511533c3974cf1"
    static let universalLink = "https://api.kangyuanhuashan.cn/app/"
}

@MainActor
final class WeChatLoginManager: ObservableObject {
    static let shared = WeChatLoginManager()

    @Published var isLoggingIn = false
    @Published var errorMessage: String?

    private var currentState: String?
    private var didBecomeActiveObserver: NSObjectProtocol?

    private init() {
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppDidBecomeActive()
            }
        }
    }

    deinit {
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }

    var isWeChatInstalled: Bool {
        #if canImport(WechatOpenSDK) || canImport(WXApi)
        WXApi.isWXAppInstalled()
        #else
        false
        #endif
    }

    func requestLogin() {
        #if canImport(WechatOpenSDK) || canImport(WXApi)
        guard WXApi.isWXAppInstalled() else {
            isLoggingIn = false
            currentState = nil
            errorMessage = "请先安装微信客户端"
            return
        }

        let state = UUID().uuidString
        currentState = state

        let request = SendAuthReq()
        request.scope = "snsapi_userinfo"
        request.state = state

        isLoggingIn = true
        WXApi.send(request) { [weak self] success in
            guard !success else { return }
            Task { @MainActor in
                self?.isLoggingIn = false
                self?.currentState = nil
                self?.errorMessage = "无法拉起微信，请稍后重试"
            }
        }
        #else
        errorMessage = "微信 SDK 尚未接入，请先安装依赖"
        #endif
    }

    #if canImport(WechatOpenSDK) || canImport(WXApi)
    func handleAuthResponse(_ response: SendAuthResp) {
        isLoggingIn = false

        guard let expectedState = currentState else {
            return
        }

        switch response.errCode {
        case 0:
            guard let code = response.code, !code.isEmpty else {
                errorMessage = "微信授权失败，未获取到授权码"
                currentState = nil
                return
            }

            guard response.state == expectedState else {
                errorMessage = "微信授权状态校验失败，请重新登录"
                currentState = nil
                return
            }

            currentState = nil
            Task {
                do {
                    try await AuthManager.shared.loginWithWeChat(code: code)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case -2:
            currentState = nil
            errorMessage = "已取消微信登录"
        case -4:
            currentState = nil
            errorMessage = "您拒绝了微信授权"
        default:
            currentState = nil
            errorMessage = response.errStr.isEmpty ? "微信登录失败，请稍后重试" : response.errStr
        }
    }
    #endif

    private func handleAppDidBecomeActive() {
        guard isLoggingIn, let pendingState = currentState else { return }

        Task { [weak self, pendingState] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                guard let self,
                      self.isLoggingIn,
                      self.currentState == pendingState else {
                    return
                }
                self.isLoggingIn = false
                self.currentState = nil
                self.errorMessage = "已取消微信登录"
            }
        }
    }
}
