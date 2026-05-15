import SwiftUI

struct VideoQuizListView: View {
    @State private var quizList: [VideoQuizShareItem] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                if UIImage(named: "home-bg") != nil {
                    Image("home-bg")
                        .resizable()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(colors: [Color(hex: "0A9200"), Color(hex: "065A00")],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    if quizList.isEmpty && !isLoading {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.5))
                            Text("暂无数据")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("视频答题列表")
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.top, 60)

                                LazyVStack(spacing: 8) {
                                    ForEach(quizList) { item in
                                        NavigationLink(destination: VideoQuizAnswerView(
                                            quizId: item.quizId,
                                            activeLinkId: item.videoQuiz.videoQuizShareStatusVO.activeLinkId
                                        )) {
                                            QuizCard(item: item)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadList()
        }
    }

    private func loadList() async {
        isLoading = true
        do {
            let items: [VideoQuizShareItem] = try await NetworkService.shared.get("/videoQuiz/getShopOwnerShareLinks")
            quizList = items
        } catch {
            print("Failed to load quiz list: \(error)")
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
        .background(Color.white)
        .cornerRadius(5)
    }
}
