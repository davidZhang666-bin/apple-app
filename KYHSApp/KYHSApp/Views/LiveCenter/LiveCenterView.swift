import SwiftUI

struct LiveWebRoute: Identifiable {
    let id = UUID()
    let url: URL
}

struct LiveCenterView: View {
    @State private var liveItems: [LiveItem] = []
    @State private var isLoading = false
    @State private var toastItem: ToastItem?
    @State private var livingWebRoute: LiveWebRoute?

    private var visibleLives: [LiveItem] {
        liveItems
            .filter { [1, 2, 4].contains($0.live_status.status) }
            .sorted { left, right in
                let lhs = normalizedStartTime(left.start_time)
                let rhs = normalizedStartTime(right.start_time)
                if lhs.isEmpty { return false }
                if rhs.isEmpty { return true }
                return lhs < rhs
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Image("home-bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // NavigationView 在当前 iOS 版本下不会自动为隐藏导航栏保留顶部安全区。
                    // 显式留出状态栏/灵动岛高度，避免品牌区贴到屏幕最上方。
                    Spacer().frame(height: 56)
                    header

                    ScrollView {
                        VStack(spacing: 0) {
                            liveList
                            Spacer().frame(height: 20)
                        }
                        .frame(minHeight: UIScreen.main.bounds.height + 1, alignment: .top)
                    }
                    .compatRefreshable {
                        print("🔄 首页下拉刷新回调已触发")
                        await refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $livingWebRoute) { route in
                NavigationView {
                    LivingWebView(url: route.url)
                        .navigationTitle("直播")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") { livingWebRoute = nil }
                            }
                        }
                }
                .navigationViewStyle(.stack)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            guard liveItems.isEmpty else { return }
            Task { await loadData() }
        }
        .toast($toastItem)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image("logo3")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            Text("康源华善")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var liveList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "0A9200"))
                    .font(.system(size: 15, weight: .semibold))
                Text("直播列表")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "222222"))
                Spacer()
                if isLoading && !liveItems.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(Color(hex: "0A9200"))
                }
            }

            if visibleLives.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(visibleLives) { item in
                        LiveListCard(liveItem: item) {
                            navigateToLive(item)
                        }
                    }
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 30))
                .foregroundColor(Color.gray.opacity(0.45))
            Text(isLoading ? "加载中…" : "暂无直播")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    private func loadData() async {
        await MainActor.run { isLoading = true }
        do {
            let params = ["page": "1", "title": "", "type": "有因"]
            print("🔄 首页直播列表开始请求，时间: \(Date()), 参数: \(params)")
            // 使用独立任务承载网络请求，避免下拉刷新任务结束时被 iOS 一并取消。
            let requestTask = Task.detached {
                try await NetworkService.shared.get("/livesMaterial/livesListwz", params: params) as [LiveItem]
            }
            let items = try await requestTask.value
            print("🔄 首页直播列表返回数据：数量=\(items.count)，IDs=\(items.map { $0.id })，状态=\(items.map { $0.live_status.status })")
            await MainActor.run {
                liveItems = items
                isLoading = false
            }
        } catch {
            let isCancel = error is CancellationError || (error as? URLError)?.code == .cancelled
            print("❌ 首页直播列表请求失败: \(error)")
            await MainActor.run {
                isLoading = false
                if !isCancel { toastItem = ToastItem(message: error.localizedDescription) }
            }
        }
    }

    private func refreshData() async {
        await loadData()
    }

    private func navigateToLive(_ item: LiveItem) {
        Task { @MainActor in
            guard let userInfo = AuthManager.shared.userInfo,
                  let rawUserID = userInfo.id else {
                toastItem = ToastItem(message: "请先登录")
                return
            }

            let userID = rawUserID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !userID.isEmpty else {
                toastItem = ToastItem(message: "用户信息无效")
                return
            }

            let trimmedName = userInfo.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let nickName = trimmedName.flatMap { $0.isEmpty ? nil : $0 } ?? "用户"

            let defaultHeadImage = "https://cdn.youinsh.cn/saas_pro/static/user/user-default.png"
            let trimmedAvatar = userInfo.avatar?.trimmingCharacters(in: .whitespacesAndNewlines)
            let headImage: String
            if let trimmedAvatar,
               let avatarURL = URL(string: trimmedAvatar),
               avatarURL.scheme?.lowercased() == "https",
               avatarURL.host != nil {
                headImage = trimmedAvatar
            } else {
                headImage = defaultHeadImage
            }

            let enterpriseID = "15579"
            let authToken = CryptoUtils.liveAuthToken(userID: userID)

            var nextComponents = URLComponents()
            nextComponents.scheme = "https"
            nextComponents.host = "live.youinsh.com"
            nextComponents.path = "/livestream/watch/"
            nextComponents.queryItems = [
                URLQueryItem(name: "liveid", value: "\(item.id)"),
                URLQueryItem(name: "enterprise_id", value: enterpriseID),
                URLQueryItem(name: "wxauth", value: "1"),
                URLQueryItem(name: "env", value: "app"),
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "auth_token", value: authToken),
                URLQueryItem(name: "nick_name", value: nickName)
            ]

            guard let nextURL = nextComponents.url else {
                toastItem = ToastItem(message: "观看地址无效")
                return
            }

            guard var authComponents = URLComponents(
                string: "https://pyapi.youinsh.com/livestreamapi/v1/user/watch_from_app_xcx/"
            ) else {
                toastItem = ToastItem(message: "直播认证地址无效")
                return
            }
            authComponents.queryItems = [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "auth_token", value: authToken),
                URLQueryItem(name: "nick_name", value: nickName),
                URLQueryItem(name: "head_image", value: headImage),
                URLQueryItem(name: "enterprise_id", value: enterpriseID),
                URLQueryItem(name: "next", value: nextURL.absoluteString)
            ]

            guard let authURL = authComponents.url else {
                toastItem = ToastItem(message: "直播认证地址无效")
                return
            }

            #if DEBUG
            print("🌐 直播WebView初始URL: \(authURL.absoluteString)")
            #endif
            livingWebRoute = LiveWebRoute(url: authURL)
        }
    }

}

struct LiveListCard: View {
    let liveItem: LiveItem
    let onTap: () -> Void

    private var status: LiveStatusPresentation {
        LiveStatusPresentation(status: liveItem.live_status.status)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: liveItem.image)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: Rectangle().fill(Color.gray.opacity(0.18))
                        }
                    }
                    .frame(width: 108, height: 76)
                    .clipped()

                    Text(status.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(status.color.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(5)
                }
                .frame(width: 108, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(liveItem.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "222222"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34, alignment: .topLeading)

                    HStack(spacing: 8) {
                        Text(normalizedStartTime(liveItem.start_time).isEmpty ? "时间待定" : normalizedStartTime(liveItem.start_time))
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "777777"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(0)

                        Spacer(minLength: 16)

                        Text("进入直播")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "0A9200"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color(hex: "0A9200"), lineWidth: 1)
                            )
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .padding(8)
            .background(Color(hex: "F8FAF8"))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color(hex: "E5EEE5"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct LiveStatusPresentation {
    let title: String
    let color: Color

    init(status: Int) {
        switch status {
        case 1:
            title = "正在直播"
            color = Color(hex: "0A9200")
        case 2:
            title = "主播不在"
            color = Color(hex: "E58B19")
        default:
            title = "未开始"
            color = Color(hex: "3A7BD5")
        }
    }
}

private func normalizedStartTime(_ value: String?) -> String {
    (value ?? "").replacingOccurrences(of: "T", with: " ")
}
