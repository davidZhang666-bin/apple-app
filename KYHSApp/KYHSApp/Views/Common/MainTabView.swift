import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var updateInfo: AppVersionInfo?
    @State private var hasCheckedForUpdate = false

    init() {
        // 设置TabBar白色背景 - iOS15+正确方式
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LiveCenterView()
                .tabItem {
                    Label("直播中心", systemImage: selectedTab == 0 ? "play.circle.fill" : "play.circle")
                }
                .tag(0)

            VideoQuizListView()
                .tabItem {
                    Label("视频答题", systemImage: selectedTab == 1 ? "questionmark.video.fill" : "questionmark.video")
                }
                .tag(1)

            UserCenterView()
                .tabItem {
                    Label("我的", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
        }
        .tint(Color(hex: "0A9200"))
        .onAppear {
            checkForUpdateIfNeeded()
        }
        .fullScreenCover(isPresented: Binding(
            get: { updateInfo != nil },
            set: { _ in
                // The update is mandatory; ignore attempts to dismiss the cover.
            }
        )) {
            if let updateInfo {
                AppVersionUpdateView(versionInfo: updateInfo)
            }
        }
    }

    private func checkForUpdateIfNeeded() {
        guard !hasCheckedForUpdate else { return }
        hasCheckedForUpdate = true

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard !currentVersion.isEmpty else { return }

        Task {
            do {
                let latest: AppVersionInfo? = try await NetworkService.shared.get(
                    "/appVersion/latest",
                    params: ["platform": "ios", "versionName": currentVersion],
                    ignoreToken: true
                )
                guard let latest, let versionName = latest.versionName, !versionName.isEmpty else { return }
                await MainActor.run {
                    updateInfo = latest
                }
            } catch {
                // Version checks are best-effort and must not block the home screen.
                print("❌ 检查App版本失败: \(error.localizedDescription)")
            }
        }
    }
}
