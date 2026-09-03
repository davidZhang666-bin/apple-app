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
    let info: String?

    init(status: Int, info: String? = nil) {
        self.status = status
        self.info = info
    }

    enum CodingKeys: String, CodingKey {
        case status, info
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(Int.self, forKey: .status) {
            status = value
        } else if let value = try? container.decode(String.self, forKey: .status),
                  let intValue = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            status = intValue
        } else {
            status = 0
        }
        info = try? container.decode(String.self, forKey: .info)
    }
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

struct VideoQuizShareItem: Codable, Identifiable, Hashable {
    let id: String
    let quizId: String
    let videoQuiz: VideoQuizDetail
}

struct VideoQuizDetail: Codable, Hashable {
    let userTitle: String
    let img: String
    let videoQuizShareStatusVO: VideoQuizShareStatus
}

struct VideoQuizShareStatus: Codable, Hashable {
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
    let isCorrect: Int?
    var isUserSelected: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, optionLabel, optionContent, isCorrect
    }
}

struct LuckyBagSetting: Codable {
    let enabled: Int?
    let points: String?
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
