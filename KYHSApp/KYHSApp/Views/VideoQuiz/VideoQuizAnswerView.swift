import SwiftUI
import AVKit

struct VideoQuizAnswerView: View {
    let quizId: String
    let activeLinkId: String

    @State private var detail: VideoQuizFullDetail?
    @State private var isVideoFinished = false
    @State private var luckyBagShow = false
    @State private var luckyBagPopupShow = false
    @State private var answerPopupShow = false
    @State private var luckyBagPoints = 0
    @State private var claimedCount = 0
    @State private var luckyBagTime: Double = 0
    @State private var luckyBagCurrentCount = 1
    @State private var luckyBagTotalCount = 3
    @State private var luckyBagSetting = LuckyBagSetting(enabled: 1, points: 5)
    @State private var luckyBagShowSeconds = 5.0
    @State private var answeringDuration = 0
    @State private var isSubmitting = false
    @State private var showAnswerList: [AnswerResultItem] = []
    @State private var player: AVPlayer?
    @State private var isPlayerPlaying = false

    // Timer for answering duration
    @State private var answerTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Video area
                if !isVideoFinished, let detail = detail {
                    ZStack {
                        VideoPlayer(player: player)
                            .frame(height: 220)
                            .onAppear {
                                setupPlayer()
                            }

                        if luckyBagShow {
                            Button(action: claimLuckyBag) {
                                Image(systemName: "giftcard.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                            .padding(.trailing, 10)
                        }
                    }
                }

                // Info area
                VStack(alignment: .leading, spacing: 12) {
                    if let detail = detail {
                        Text(detail.userTitle)
                            .font(.system(size: 16, weight: .bold))

                        HStack {
                            Text("答题截止时间:")
                                .font(.system(size: 12))
                            Text(detail.expireTime ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "F08D2B"))
                        }
                        .padding(5)
                        .background(Color(hex: "F0F0F0"))
                        .cornerRadius(3)

                        // Instructions
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(hex: "188600"))
                                    .font(.system(size: 12))
                                Text("播放完成后才能答题")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "188600"))
                            }
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(hex: "188600"))
                                    .font(.system(size: 12))
                                Text("答题完成后，点击底部\u{201C}提交\u{201D}按钮完成答题")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "188600"))
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "EBFFE1"))
                        .cornerRadius(5)

                        // Questions
                        if isVideoFinished {
                            ForEach(Array(detail.questions.enumerated()), id: \.element.id) { qIndex, question in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("问题")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "188600"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: "EBFFE1"))
                                        .cornerRadius(3)

                                    Text("\(question.questionContent)\(question.questionType == "single" ? "(单选)" : "(多选)")")
                                        .font(.system(size: 13, weight: .bold))

                                    ForEach(Array(question.options.enumerated()), id: \.element.id) { oIndex, option in
                                        let isSelected = option.isUserSelected
                                        Button(action: {
                                            selectOption(qIndex: qIndex, oIndex: oIndex, questionType: question.questionType)
                                        }) {
                                            HStack {
                                                Text(option.optionLabel)
                                                    .fontWeight(.bold)
                                                Text(option.optionContent)
                                                    .font(.system(size: 13))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(10)
                                            .background(isSelected ? Color(hex: "EBFFE1") : Color(hex: "F2F2F2"))
                                            .foregroundColor(isSelected ? Color(hex: "188600") : .primary)
                                            .cornerRadius(5)
                                        }
                                    }
                                }
                                .padding(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "play.rectangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("请先完成上方视频观看")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }

                        // Submit button
                        if isVideoFinished {
                            Button(action: handleSubmit) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                } else {
                                    Text("提交")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                }
                            }
                            .background(Color(hex: "0A9200"))
                            .cornerRadius(10)
                            .disabled(isSubmitting)
                            .padding(.top, 10)
                        }
                    }
                }
                .padding(15)
            }
        }
        .navigationTitle("视频答题")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
            await loadLuckyBagSettings()
            await loadLuckyBagShowTime()
        }
        .onDisappear {
            player?.pause()
            answerTimer?.invalidate()
        }
        // Lucky bag popup
        .overlay {
            if luckyBagPopupShow {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { luckyBagPopupShow = false }

                    VStack(spacing: 12) {
                        Text("开启福袋获得")
                            .font(.system(size: 14))
                        Text("\(luckyBagPoints)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.red)
                        Text("积分")
                            .font(.system(size: 12))
                        Button("确定") {
                            luckyBagPopupShow = false
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "0A9200"))
                        .cornerRadius(10)
                    }
                    .padding(20)
                    .frame(width: 260)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 20)
                }
            }
        }
        // Answer result popup
        .overlay {
            if answerPopupShow {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text("视频答题结果")
                            .font(.headline)

                        ForEach(Array(showAnswerList.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(index + 1).")
                                Text(item.optionLabel)
                                    .bold()
                                Spacer()
                                Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(item.isCorrect ? Color(hex: "188600") : Color(hex: "BC0000"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(item.isCorrect ? Color(hex: "E6FFD4") : Color(hex: "FFDFD4"))
                            .foregroundColor(item.isCorrect ? Color(hex: "188600") : Color(hex: "BC0000"))
                            .cornerRadius(25)
                        }

                        Button("重新答题") {
                            handleRestart()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "0A9200"))
                        .cornerRadius(10)

                        Button(action: handleSubmitAnswer) {
                            Text("提交")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .background(Color(hex: "0A9200"))
                        .cornerRadius(10)
                        .disabled(isSubmitting)
                    }
                    .padding(25)
                    .frame(width: 300)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
            }
        }
    }

    // MARK: - Data

    private func loadData() async {
        do {
            var d: VideoQuizFullDetail = try await NetworkService.shared.get("/videoQuiz/getDetail", params: ["id": quizId])
            luckyBagTime = d.duration / Double(luckyBagTotalCount)
            d.videoM3u8Url = NetworkService.shared.spliceVideoURL(d.videoM3u8Url)
            for i in d.questions.indices {
                for j in d.questions[i].options.indices {
                    d.questions[i].options[j].isUserSelected = false
                }
            }
            detail = d
        } catch {
            print("Failed to load quiz detail: \(error)")
        }
    }

    private func loadLuckyBagSettings() async {
        do {
            let setting: LuckyBagSetting = try await NetworkService.shared.get("/videoQuizLuckyBagSetting/getSetting")
            luckyBagSetting = setting
        } catch {
            print("Failed to load lucky bag settings: \(error)")
        }
    }

    private func loadLuckyBagShowTime() async {
        do {
            let result: LuckyBagShowTime = try await NetworkService.shared.get("/videoQuizLuckyBagSetting/getShowTime")
            if let val = result.value, let d = Double(val) {
                luckyBagShowSeconds = d
            }
        } catch {
            print("Failed to load lucky bag show time: \(error)")
        }
    }

    // MARK: - Video Player

    private func setupPlayer() {
        guard let detail = detail, let url = URL(string: detail.videoM3u8Url) else { return }
        player = AVPlayer(url: url)
        player?.play()

        // Monitor playback for lucky bag
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard let player = player, let currentTime = player.currentItem?.currentTime().seconds else {
                timer.invalidate()
                return
            }

            // Check video ended
            if let duration = player.currentItem?.duration.seconds, duration > 0, currentTime >= duration - 1 {
                isVideoFinished = true
                startAnswerTimer()
                timer.invalidate()
                return
            }

            // Check lucky bag
            if claimedCount >= luckyBagTotalCount || luckyBagSetting.enabled != 1 { return }
            if currentTime >= luckyBagTime * Double(luckyBagCurrentCount) {
                luckyBagShow = true
                DispatchQueue.main.asyncAfter(deadline: .now() + luckyBagShowSeconds) {
                    luckyBagShow = false
                }
                if luckyBagCurrentCount < luckyBagTotalCount {
                    luckyBagCurrentCount += 1
                }
            }
        }
    }

    private func startAnswerTimer() {
        answerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            answeringDuration += 1
        }
    }

    // MARK: - Lucky Bag

    private func claimLuckyBag() {
        luckyBagShow = false
        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.get("/videoQuiz/claimLuckyBag", params: ["id": activeLinkId])
                claimedCount += 1
                luckyBagPoints = luckyBagSetting.points ?? 0
                luckyBagPopupShow = true
            } catch {
                print("Lucky bag claim failed: \(error)")
            }
        }
    }

    // MARK: - Selection

    private func selectOption(qIndex: Int, oIndex: Int, questionType: String) {
        guard var detail = detail else { return }
        if questionType == "single" {
            for i in detail.questions[qIndex].options.indices {
                detail.questions[qIndex].options[i].isUserSelected = (i == oIndex)
            }
        } else {
            detail.questions[qIndex].options[oIndex].isUserSelected.toggle()
        }
        self.detail = detail
    }

    // MARK: - Submit

    private func handleSubmit() {
        guard let detail = detail else { return }
        let allAnswered = detail.questions.allSatisfy { question in
            question.options.contains { $0.isUserSelected }
        }
        guard allAnswered else {
            return
        }

        answerTimer?.invalidate()

        // Build show answer list
        showAnswerList = detail.questions.map { question in
            var result = AnswerResultItem(optionLabel: "", isCorrect: false)
            if question.questionType == "single" {
                for option in question.options {
                    if option.isUserSelected {
                        result.optionLabel = option.optionLabel
                    }
                    if option.isCorrect == true && option.isUserSelected {
                        result.isCorrect = true
                    }
                }
                if !result.isCorrect {
                    result.isCorrect = false
                }
            } else {
                let selected = question.options.filter { $0.isUserSelected }.map { $0.optionLabel }
                let correct = question.options.filter { $0.isCorrect == true }.map { $0.optionLabel }
                result.optionLabel = selected.joined(separator: ",")
                result.isCorrect = selected.count == correct.count && selected.allSatisfy { correct.contains($0) }
            }
            return result
        }

        answerPopupShow = true
    }

    private func handleSubmitAnswer() {
        guard let detail = detail else { return }
        isSubmitting = true

        var answerItems: [QuizAnswerItem] = []
        for question in detail.questions {
            for option in question.options {
                if option.isUserSelected {
                    answerItems.append(QuizAnswerItem(questionId: question.id, optionId: option.id))
                }
            }
        }

        let body = QuizSubmitBody(linkId: activeLinkId, answer: answerItems, answeringDuration: answeringDuration)

        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.post("/videoQuiz/submitAnswer", body: body, contentType: "application/json")
                answerPopupShow = false
                // Navigate to success
            } catch {
                print("Submit failed: \(error)")
            }
            isSubmitting = false
        }
    }

    private func handleRestart() {
        answerPopupShow = false
        isVideoFinished = false
        showAnswerList = []
        answeringDuration = 0
        if var detail = detail {
            for i in detail.questions.indices {
                for j in detail.questions[i].options.indices {
                    detail.questions[i].options[j].isUserSelected = false
                }
            }
            self.detail = detail
        }
        // Restart video
        player?.seek(to: .zero)
        player?.play()
    }
}

// MARK: - Answer Result Item

struct AnswerResultItem {
    var optionLabel: String
    var isCorrect: Bool
}
