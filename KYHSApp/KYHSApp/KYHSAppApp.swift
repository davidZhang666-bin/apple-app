import SwiftUI

@main
@MainActor
struct KYHSAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onOpenURL { url in
                appDelegate.handleOpenURL(url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                appDelegate.handleUniversalLink(userActivity)
            }
        }
    }
}
