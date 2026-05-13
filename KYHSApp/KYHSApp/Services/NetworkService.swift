import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的请求地址"
        case .unauthorized: return "登录已过期，请重新登录"
        case .serverError(let msg): return msg
        case .decodingError: return "数据解析错误"
        case .networkUnavailable: return "网络错误，请稍后重试"
        }
    }
}

final class NetworkService {
    static let shared = NetworkService()

    private let baseURL = "https://api.kangyuanhuashan.cn"
    private let videoBaseURL = "http://116.132.104.106:31000"

    private init() {}

    func request<T: Codable>(_ path: String,
                              method: String = "GET",
                              body: Encodable? = nil,
                              contentType: String = "application/x-www-form-urlencoded",
                              ignoreToken: Bool = false) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if !ignoreToken, let token = KeychainManager.shared.getToken() {
            request.setValue(token, forHTTPHeaderField: "token")
        }

        if path != "/upload/uploadFile" {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let body = body {
            if contentType == "application/json" {
                request.httpBody = try JSONEncoder().encode(body)
            } else {
                request.httpBody = try formEncode(body)
            }
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let rawJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = rawJSON["code"] as? Int else {
            throw NetworkError.decodingError
        }

        if code == 401 && path != "/sysUser/appLogin" {
            await MainActor.run { AuthManager.shared.logout() }
            throw NetworkError.unauthorized
        }

        if code == 500 {
            throw NetworkError.serverError(rawJSON["msg"] as? String ?? "服务器错误")
        }

        // Try direct decode first, then try .data field
        if let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }
        if let dataField = rawJSON["data"] {
            let dataJSON = try JSONSerialization.data(withJSONObject: dataField)
            if let decoded = try? JSONDecoder().decode(T.self, from: dataJSON) {
                return decoded
            }
        }
        throw NetworkError.decodingError
    }

    func get<T: Codable>(_ path: String, params: [String: String]? = nil) async throws -> T {
        var fullPath = path
        if let params, !params.isEmpty {
            let query = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            fullPath += "?" + query
        }
        return try await request(fullPath)
    }

    func post<T: Codable>(_ path: String, body: Encodable? = nil, contentType: String = "application/x-www-form-urlencoded") async throws -> T {
        return try await request(path, method: "POST", body: body, contentType: contentType)
    }

    func spliceVideoURL(_ relativePath: String) -> String {
        videoBaseURL + relativePath
    }

    private func formEncode(_ body: Encodable) throws -> Data {
        let data = try JSONEncoder().encode(body)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let query = dict.compactMap { key, value -> String? in
            guard let str = value as? CustomStringConvertible else { return nil }
            return "\(key)=\(str.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str.description)"
        }.joined(separator: "&")
        return Data(query.utf8)
    }
}
