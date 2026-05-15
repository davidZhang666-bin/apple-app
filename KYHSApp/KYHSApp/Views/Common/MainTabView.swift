import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

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
    }
}
