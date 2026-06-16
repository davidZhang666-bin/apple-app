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
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("视频答题列表")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)
                        .padding(.horizontal, 16)

                    ScrollView {
                        if quizList.isEmpty && !isLoading {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("暂无数据")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 120)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(quizList) { item in
                                    Button(action: {
                                        selectedItem = item
                                        isAnswerActive = true
                                    }) {
                                        QuizCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .compatRefreshable {
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

    private func loadList() async {
        isLoading = true
        let work = Task.detached {
            do {
                let items: [VideoQuizShareItem] = try await NetworkService.shared.get("/videoQuiz/getShopOwnerShareLinks")
                await MainActor.run {
                    self.quizList = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let isCancel = error is CancellationError || (error as? URLError)?.code == .cancelled
                    if !isCancel {
                        self.toastItem = ToastItem(message: error.localizedDescription)
                    }
                    self.isLoading = false
                }
            }
        }
        _ = await work.value
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
        .background(Color.white)
        .cornerRadius(5)
    }
}
