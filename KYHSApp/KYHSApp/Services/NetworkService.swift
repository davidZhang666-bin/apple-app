import Foundation

struct EmptyResponse: Codable {}

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
            print("🔑 Token已读取, 长度: \(token.count)")
            print("🔑 Token前10位: \(token.prefix(10))...")
            request.setValue(token, forHTTPHeaderField: "token")
        } else {
            print("❌ Token未找到或为空")
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

        print("🌐 \(method) \(url.absoluteString)")
        if let body = body, let bodyData = try? JSONEncoder().encode(body),
           let bodyStr = String(data: bodyData, encoding: .utf8) {
            print("📤 请求参数: \(bodyStr)")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResp = response as? HTTPURLResponse {
            print("📡 \(httpResp.statusCode) \(url.lastPathComponent)")
        }
        if let raw = String(data: data, encoding: .utf8) {
            print("📦 Response: \(raw.prefix(500))")
        }

        guard let rawJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = rawJSON["code"] as? Int else {
            throw NetworkError.decodingError
        }

        if code == 401 && !path.hasPrefix("/sysUser/appLogin") {
            await MainActor.run { AuthManager.shared.logout() }
            throw NetworkError.unauthorized
        }

        if code != 200 {
            throw NetworkError.serverError(rawJSON["msg"] as? String ?? "请求失败")
        }

        // 对齐 demo: code == 200 时只解码 data 字段
        if code == 200 {
            if let dataField = rawJSON["data"] {
                // 处理空字符串或空数据的情况（接口返回成功但无数据）
                if (dataField is String && (dataField as? String ?? "").isEmpty) ||
                   (dataField is NSNull) {
                    if let empty = EmptyResponse() as? T {
                        return empty
                    }
                }
                // 只有字典或数组类型才用 JSONSerialization
                if dataField is [String: Any] || dataField is [Any] {
                    do {
                        let dataJSON = try JSONSerialization.data(withJSONObject: dataField)
                        do {
                            return try JSONDecoder().decode(T.self, from: dataJSON)
                        } catch {
                            print("❌ 解码data字段失败: \(error)")
                            print("📄 data内容: \(String(data: dataJSON, encoding: .utf8) ?? "")")
                            throw NetworkError.decodingError
                        }
                    } catch {
                        print("❌ JSON序列化失败: \(error), dataField类型: \(type(of: dataField))")
                    }
                } else {
                    print("ℹ️ dataField不是字典/数组类型: \(type(of: dataField)), 值: \(dataField)")
                }
                // 其他类型或序列化失败，尝试返回空响应
                if let empty = EmptyResponse() as? T {
                    return empty
                }
                throw NetworkError.decodingError
            }
            print("❌ code=200但无data字段")
            throw NetworkError.decodingError
        }

        // 非 200 的其他 code，返回完整响应（兼容 appLogin 401 等场景）
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ 解码完整响应失败: \(error)")
            print("📄 code=\(code), 响应: \(String(data: data, encoding: .utf8) ?? "")")
            throw NetworkError.decodingError
        }
    }

    func get<T: Codable>(_ path: String, params: [String: String]? = nil, ignoreToken: Bool = false) async throws -> T {
        var fullPath = path
        if let params, !params.isEmpty {
            let query = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            fullPath += "?" + query
        }
        return try await request(fullPath, ignoreToken: ignoreToken)
    }

    func post<T: Codable>(_ path: String, body: Encodable? = nil, contentType: String = "application/x-www-form-urlencoded", ignoreToken: Bool = false) async throws -> T {
        return try await request(path, method: "POST", body: body, contentType: contentType, ignoreToken: ignoreToken)
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
