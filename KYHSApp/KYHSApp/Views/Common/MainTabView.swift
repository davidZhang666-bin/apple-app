import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LiveCenterView()
                .tabItem {
                    Label("直播中心", systemImage: selectedTab == 0 ? "dot.radiowaves.left.forward" : "dot.radiowaves.left")
                }
                .tag(0)

            VideoQuizListView()
                .tabItem {
                    Label("视频答题", systemImage: selectedTab == 1 ? "questionmark.video.fill" : "questionmark.video")
                }
                .tag(1)

            UserCenterView()
                .tabItem {
                    Label("个人中心", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
        }
        .tint(Color(hex: "0A9200"))
    }
}
