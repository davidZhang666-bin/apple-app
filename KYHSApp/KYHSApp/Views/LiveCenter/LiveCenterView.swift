import SwiftUI
import AVKit
import Combine

struct LiveWebRoute: Identifiable {
    let id = UUID()
    let url: URL
}

struct LiveCenterView: View {
    @State private var liveItems: [LiveItem] = []
    @State private var livingStreamURL: String?
    @State private var reservedList: [ReservedLiveItem] = []
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var toastItem: ToastItem?
    @State private var livingWebRoute: LiveWebRoute?

    private var livingInfo: LiveItem? { liveItems.first(where: { $0.live_status.status == 1 }) }
    private var trailerList: [LiveItem] { liveItems.filter { $0.live_status.status == 4 } }
    private var bookedLiveIds: Set<String> {
        Set(reservedList.compactMap { $0.liveId })
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Image("home-bg")
                    .resizable()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header（移出 ScrollView，避免下拉菊花贴在状态栏下被遮）
                    HStack {
                        Image("logo3")
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text("康源华善")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    ScrollView {
                        VStack(spacing: 12) {
                            // Living area
                            if let living = livingInfo {
                                LivingPreviewCard(liveItem: living, streamURL: livingStreamURL) {
                                    navigateToLivingWebview(living)
                                }
                                .padding(.horizontal, 16)
                            }

                            // Trailer area
                            TrailerSection(trailerList: trailerList, bookedLiveIds: bookedLiveIds) { liveId in
                                toggleReservation(liveId: liveId)
                            }
                            .padding(.horizontal, 16)

                            Spacer().frame(height: 20)
                        }
                    }
                    .compatRefreshable {
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
                                Button("返回") {
                                    livingWebRoute = nil
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Task { await loadData() }
        }
        .toast($toastItem)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        do {
            let params: [String: String] = ["page": "1", "title": "", "type": "有因"]
            let items: [LiveItem] = try await NetworkService.shared.get("/livesMaterial/livesListwz", params: params)

            var streamURL: String?
            if let living = items.first(where: { $0.live_status.status == 1 }) {
                let info: LiveStreamInfo? = try? await NetworkService.shared.get("/livesMaterial/getPullUrl", params: ["liveid": "\(living.id)"])
                streamURL = info?.pull_hls
            }

            var reserved: [ReservedLiveItem] = []
            if items.contains(where: { $0.live_status.status == 4 }) {
                if let response: ReservedLiveListResponse = try? await NetworkService.shared.get("/livesMaterial/getReservedLiveList") {
                    reserved = response.list
                }
            }

            liveItems = items
            livingStreamURL = streamURL
            reservedList = reserved
            isLoading = false
        } catch {
            let isCancel = error is CancellationError || (error as? URLError)?.code == .cancelled
            if !isCancel {
                toastItem = ToastItem(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await loadData()
        isRefreshing = false
    }

    private func fetchStreamURL(liveId: Int) async {
        do {
            let info: LiveStreamInfo = try await NetworkService.shared.get("/livesMaterial/getPullUrl", params: ["liveid": "\(liveId)"])
            livingStreamURL = info.pull_hls
        } catch {
            toastItem = ToastItem(message: error.localizedDescription)
        }
    }

    private func fetchReservations() async {
        do {
            let response: ReservedLiveListResponse = try await NetworkService.shared.get("/livesMaterial/getReservedLiveList")
            reservedList = response.list
        } catch {
            toastItem = ToastItem(message: error.localizedDescription)
        }
    }

    private func toggleReservation(liveId: Int) {
        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.get("/livesMaterial/reserveLive", params: ["liveId": "\(liveId)"])
                await fetchReservations()
            } catch {
                toastItem = ToastItem(message: error.localizedDescription)
            }
        }
    }

    private func navigateToLivingWebview(_ item: LiveItem) {
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
            let secret = "3f1e6591f68710f5c804eff7bb963ad8"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = "yyyyMMdd"
            let currentDate = formatter.string(from: Date())
            let authToken = CryptoUtils.md5("\(secret)\(currentDate)\(userID)")

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


// MARK: - Preview Player (无控件)

struct PreviewPlayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Living Preview Card

struct LivingPreviewCard: View {
    let liveItem: LiveItem
    let streamURL: String?
    let onWatch: () -> Void

    @State private var player: AVPlayer?
    @State private var isPreviewLoading = false

    var body: some View {
        ZStack {
            // Video preview
            if let urlStr = streamURL, let url = URL(string: urlStr) {
                PreviewPlayerView(player: player)
                    .frame(height: 194)
                    .cornerRadius(5)
                    .allowsHitTesting(false)
                    .onAppear {
                        // 每次回到该视图都重建 player：HLS 直播流被 pause 后
                        // 旧 AVPlayerItem 会 stalled，需要重新拉 manifest 才能恢复
                        let p = AVPlayer(url: url)
                        p.isMuted = true
                        player = p
                        isPreviewLoading = true
                        p.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player?.replaceCurrentItem(with: nil)
                        player = nil
                        isPreviewLoading = false
                    }
                    .onReceive(
                        player?.publisher(for: \.timeControlStatus).eraseToAnyPublisher()
                            ?? Just(AVPlayer.TimeControlStatus.paused).eraseToAnyPublisher()
                    ) { status in
                        if status == .playing {
                            isPreviewLoading = false
                        }
                    }
            } else {
                AsyncImage(url: URL(string: liveItem.image)) { image in
                    image.resizable()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(height: 194)
                .cornerRadius(5)
            }

            // Overlay
            VStack {
                HStack {
                    Text("康源华善小课堂开课啦")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    if isPreviewLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.mini)
                                .tint(.white)
                            Text("加载中")
                                .foregroundColor(.white)
                                .font(.system(size: 11))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(10)
                    }
                }
                Spacer()
                Button(action: onWatch) {
                    HStack {
                        Image(systemName: "play.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        Text("观看直播")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
            }
            .padding(15)
        }
    }
}

// MARK: - Trailer Section

struct TrailerSection: View {
    let trailerList: [LiveItem]
    let bookedLiveIds: Set<String>
    let onReserve: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 10))
                Text("直播预告")
                    .font(.system(size: 14, weight: .bold))
            }

            if let first = trailerList.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 15) {
                        AsyncImage(url: URL(string: first.image)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 106, height: 71)
                        .clipped()
                        .cornerRadius(5)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(first.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            Text("直播人：\(first.nickname ?? "")")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("直播时间：\(formattedLiveTime(first.start_time))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { onReserve(first.id) }) {
                        Text(bookedLiveIds.contains("\(first.id)") ? "取消预约" : "立即预约")
                            .font(.system(size: 14))
                            .foregroundColor(bookedLiveIds.contains("\(first.id)") ? Color(hex: "6C6C6C") : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(bookedLiveIds.contains("\(first.id)") ? Color(hex: "CCCCCC") : Color(hex: "0A9200"))
                            .cornerRadius(5)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("暂无可预约直播")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(height: 150)
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(5)
    }

    private func formattedLiveTime(_ time: String?) -> String {
        time?.replacingOccurrences(of: "T", with: " ") ?? ""
    }
}
