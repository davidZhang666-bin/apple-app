import SwiftUI

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

    func login(token: String, userId: Int) {
        KeychainManager.shared.saveToken(token)
        KeychainManager.shared.saveUserId(String(userId))
        isAuthenticated = true
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
            userInfo = info
            cacheUserInfo(info)
        } catch {
            print("Failed to fetch user info: \(error)")
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
