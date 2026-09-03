import SwiftUI

struct VideoQuizListView: View {
    @State private var quizList: [VideoQuizShareItem] = []
    @State private var isLoading = false
    @State private var toastItem: ToastItem?
    @State private var selectedItem: VideoQuizShareItem?
    @State private var isAnswerActive = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("home-bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    header

                    ScrollView {
                        VStack(spacing: 0) {
                            quizListSection
                            Spacer().frame(height: 20)
                        }
                        .frame(minHeight: UIScreen.main.bounds.height + 1, alignment: .top)
                    }
                    .compatRefreshable {
                        print("🔄 视频答题下拉刷新回调已触发")
                        await loadList()
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    isActive: $isAnswerActive,
                    destination: {
                        if let item = selectedItem {
                            VideoQuizAnswerView(
                                quizId: item.quizId,
                                linkId: item.id,
                                activeLinkId: item.videoQuiz.videoQuizShareStatusVO.activeLinkId,
                                popToRoot: { isAnswerActive = false }
                            )
                        }
                    },
                    label: { EmptyView() }
                )
            )
        }
        .navigationViewStyle(.stack)
        .task {
            await loadList()
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

    private var quizListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "0A9200"))
                    .font(.system(size: 15, weight: .semibold))
                Text("视频答题")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "222222"))
                Spacer()
                if isLoading && !quizList.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color(hex: "0A9200"))
                }
            }

            if quizList.isEmpty && !isLoading {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.45))
                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(quizList) { item in
                        Button(action: {
                            selectedItem = item
                            isAnswerActive = true
                        }) {
                            QuizCard(item: item)
                        }
                        .buttonStyle(.plain)
                                    }
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 12)
    }

    private func loadList() async {
        isLoading = true
        do {
            print("🔄 视频答题列表开始请求，时间: \(Date())")
            // 使用独立任务承载网络请求，避免下拉刷新任务结束时被 iOS 一并取消。
            let requestTask = Task.detached {
                try await NetworkService.shared.get("/videoQuiz/getShopOwnerShareLinks") as [VideoQuizShareItem]
            }
            let items = try await requestTask.value
            print("🔄 视频答题列表返回数据：数量=\(items.count)，IDs=\(items.map { $0.id })")
            quizList = items
        } catch {
            let isCancel = error is CancellationError || (error as? URLError)?.code == .cancelled
            print("❌ 视频答题列表请求失败: \(error)")
            if !isCancel {
                toastItem = ToastItem(message: error.localizedDescription)
            }
        }
        isLoading = false
    }
}

// MARK: - Quiz Card

struct QuizCard: View {
    let item: VideoQuizShareItem

    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: NetworkService.shared.spliceVideoURL(item.videoQuiz.img))) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 106, height: 71)
            .clipped()
            .cornerRadius(5)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.videoQuiz.userTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                Text("链接截止时间：\(item.videoQuiz.videoQuizShareStatusVO.activeLinkExpireTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(hex: "F8FAF8"))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color(hex: "E5EEE5"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
