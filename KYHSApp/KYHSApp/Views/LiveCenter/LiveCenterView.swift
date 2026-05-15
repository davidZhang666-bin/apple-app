import SwiftUI
import AVKit

struct LiveCenterView: View {
    @State private var liveItems: [LiveItem] = []
    @State private var livingInfo: LiveItem?
    @State private var livingStreamURL: String?
    @State private var reservedList: [ReservedLiveItem] = []
    @State private var page = 1
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var toastItem: ToastItem?
    @State private var showLivingWebview = false
    @State private var livingWebviewURL: String?

    private var isLiving: Bool { livingInfo != nil }
    private var trailerList: [LiveItem] { liveItems.filter { $0.live_status.status == 4 } }
    private var endList: [LiveItem] { liveItems.filter { $0.live_status.status == 3 } }
    private var bookedLiveIds: Set<String> {
        Set(reservedList.compactMap { $0.liveId })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Image("home-bg")
                    .resizable()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            Image("logo3")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("康源华善")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.horizontal, 16)

                        // Living area
                        if isLiving, let living = livingInfo {
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

                        // Past streams
                        PastStreamsSection(endList: endList, hasMore: endList.count > 0) {
                            loadMore()
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 20)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task { await loadData() }
        }
        .toast($toastItem)
        .navigationDestination(isPresented: $showLivingWebview) {
            if let urlStr = livingWebviewURL, let url = URL(string: urlStr) {
                LivingWebView(url: url)
                    .navigationTitle("直播")
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        page = 1
        do {
            let params: [String: String] = ["page": "1", "title": "", "type": "有因"]
            let items: [LiveItem] = try await NetworkService.shared.get("/livesMaterial/livesListwz", params: params)
            liveItems = items

            // Find current live
            if let living = items.first(where: { $0.live_status.status == 1 }) {
                livingInfo = living
                await fetchStreamURL(liveId: living.id)
            }

            // Fetch reservations if there are trailers
            if items.contains(where: { $0.live_status.status == 4 }) {
                await fetchReservations()
            }
        } catch {
            toastItem = ToastItem(message: error.localizedDescription)
        }
        isLoading = false
    }

    private func refreshData() async {
        isRefreshing = true
        await loadData()
        isRefreshing = false
    }

    private func loadMore() {
        page += 1
        Task {
            do {
                let params: [String: String] = ["page": "\(page)", "title": "", "type": "有因"]
                let moreItems: [LiveItem] = try await NetworkService.shared.get("/livesMaterial/livesListwz", params: params)
                if moreItems.isEmpty {
                    page -= 1
                } else {
                    liveItems.append(contentsOf: moreItems.filter { $0.live_status.status == 3 })
                }
            } catch {
                page -= 1
            }
        }
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
        let isBooked = bookedLiveIds.contains("\(liveId)")
        let message = isBooked ? "确定取消预约吗？" : "确定预约吗？"

        // Using alert approach since we can't use uni.showModal directly
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
        Task {
            guard let userInfo = AuthManager.shared.userInfo, let userId = userInfo.id else {
                toastItem = ToastItem(message: "请先登录")
                return
            }

            let secret = "3f1e6591f68710f5c804eff7bb963ad8"
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            let currentDate = formatter.string(from: today)
            let md5Str = "\(secret)\(currentDate)\(userId)"
            let authToken = CryptoUtils.md5(md5Str)

            let params: [String: String] = [
                "user_id": "\(userId)",
                "auth_token": authToken,
                "nick_name": userInfo.name ?? "用户",
                "head_image": userInfo.avatar ?? "https://cdn.youinsh.cn/saas_pro/static/user/user-default.png",
                "enterprise_id": "15579",
                "next": "https://live.youinsh.com/livestream/watch/?liveid=\(item.id)&enterprise_id=15579&env=app&extra_info=xxx"
            ]

            do {
                let urlStr = "https://pyapi.youinsh.com/livestreamapi/v1/user/watch_from_app_xcx/"
                var components = URLComponents(string: urlStr)!
                components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
                guard let url = components.url else { return }

                let (data, _) = try await URLSession.shared.data(from: url)
                // After auth, navigate to webview with third_user_id
                livingWebviewURL = "https://live.youinsh.com/livestream/watch/?liveid=\(item.id)&enterprise_id=15579&env=app&extra_info=xxx&third_user_id=\(userId)"
                showLivingWebview = true
            } catch {
                toastItem = ToastItem(message: "观看直播失败")
            }
        }
    }
}

// MARK: - Empty Response

struct EmptyResponse: Codable {}

// MARK: - Living Preview Card

struct LivingPreviewCard: View {
    let liveItem: LiveItem
    let streamURL: String?
    let onWatch: () -> Void

    var body: some View {
        ZStack {
            // Video preview
            if let urlStr = streamURL, let url = URL(string: urlStr) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 194)
                    .cornerRadius(5)
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
                            HStack(spacing: 10) {
                                Text("直播人：\(first.nickname ?? "")")
                                    .font(.system(size: 12))
                                Text("预约人数：10人")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            Text("直播时间：\(first.start_time ?? "")")
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
}

// MARK: - Past Streams Section

struct PastStreamsSection: View {
    let endList: [LiveItem]
    let hasMore: Bool
    let onLoadMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("过往直播")
                .font(.system(size: 15, weight: .bold))

            if endList.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("暂无过往直播")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(height: 150)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(endList) { item in
                        HStack(spacing: 15) {
                            AsyncImage(url: URL(string: item.image)) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 100, height: 71)
                            .clipped()
                            .cornerRadius(5)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                Text("直播时间：\(item.start_time ?? "")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                HStack(spacing: 10) {
                                    Text("直播人：\(item.nickname ?? "")")
                                    Text("观看人次：\(item.tp_pv ?? 0)")
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            }
                        }
                    }

                    if hasMore {
                        Button("加载更多") {
                            onLoadMore()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0A9200"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(5)
    }
}
