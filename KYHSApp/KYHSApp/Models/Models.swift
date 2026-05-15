import Foundation

// MARK: - User

struct UserInfo: Codable {
    let id: String?
    let name: String?
    let phone: String?
    let avatar: String?
    let sex: Int?
    let birthdate: String?
    let remark: String?
    let shopName: String?
    let shopUserName: String?
}

struct LoginResponse: Codable {
    let token: String?
    let userId: String?
}

// MARK: - Live Stream

struct LiveItem: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String
    let nickname: String?
    let start_time: String?
    let tp_pv: Int?
    let live_status: LiveStatusWrapper
}

struct LiveStatusWrapper: Codable {
    let status: Int
}

struct LiveStreamInfo: Codable {
    let pull_hls: String?
}

struct ReservedLiveItem: Codable {
    let liveId: String?
}

struct ReservedLiveListResponse: Codable {
    let list: [ReservedLiveItem]
}

// MARK: - Video Quiz

struct VideoQuizShareItem: Codable, Identifiable {
    var id: String { quizId }
    let quizId: String
    let videoQuiz: VideoQuizDetail
}

struct VideoQuizDetail: Codable {
    let userTitle: String
    let img: String
    let videoQuizShareStatusVO: VideoQuizShareStatus
}

struct VideoQuizShareStatus: Codable {
    let activeLinkExpireTime: String
    let activeLinkId: String
}

struct VideoQuizFullDetail: Codable {
    let id: String
    let userTitle: String
    var videoM3u8Url: String
    let duration: Double
    let expireTime: String?
    var questions: [QuizQuestion]
}

struct QuizQuestion: Codable, Identifiable {
    let id: String
    let questionContent: String
    let questionType: String
    var options: [QuizOption]
}

struct QuizOption: Codable, Identifiable {
    let id: String
    let optionLabel: String
    let optionContent: String
    let isCorrect: Bool?
    var isUserSelected: Bool = false
}

struct LuckyBagSetting: Codable {
    let enabled: Int?
    let points: Int?
}

struct LuckyBagShowTime: Codable {
    let value: String?
}

struct ClockInResult: Codable {
    let rewardType: String?
    let integralAmount: Int?
    let physicalName: String?
}

struct QuizAnswerItem: Codable {
    let questionId: String
    let optionId: String
}

struct QuizSubmitBody: Codable {
    let linkId: String
    let answer: [QuizAnswerItem]
    let answeringDuration: Int
}
