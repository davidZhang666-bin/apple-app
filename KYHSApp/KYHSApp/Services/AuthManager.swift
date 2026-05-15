import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var userInfo: UserInfo?

    private init() {
        checkAuth()
    }

    func checkAuth() {
        if KeychainManager.shared.getToken() != nil {
            isAuthenticated = true
            loadCachedUserInfo()
        }
    }

    func login(token: String, userId: String) {
        print("🔐 保存Token, 长度: \(token.count)")
        print("🔐 保存UserId: \(userId)")
        KeychainManager.shared.saveToken(token)
        KeychainManager.shared.saveUserId(userId)
        isAuthenticated = true
        // 验证是否保存成功
        let savedToken = KeychainManager.shared.getToken()
        print("🔐 验证Token保存结果: \(savedToken != nil ? "成功" : "失败")")
    }

    func logout() {
        KeychainManager.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "cachedUserInfo")
        userInfo = nil
        isAuthenticated = false
    }

    func fetchUserInfo() async {
        do {
            let info: UserInfo = try await NetworkService.shared.post("/sysUser/getUserInfo")
            print("👤 获取到用户信息: \(info.name ?? "无"), phone: \(info.phone ?? "无")")
            userInfo = info
            cacheUserInfo(info)
        } catch {
            print("❌ 获取用户信息失败: \(error)")
        }
    }

    private func loadCachedUserInfo() {
        if let data = UserDefaults.standard.data(forKey: "cachedUserInfo"),
           let info = try? JSONDecoder().decode(UserInfo.self, from: data) {
            userInfo = info
        }
    }

    private func cacheUserInfo(_ info: UserInfo) {
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: "cachedUserInfo")
        }
    }
}
