import Foundation
import UIKit

// App 里统一使用的网络错误类型。
// 这样页面上展示错误时，不需要知道底层是 HTTP、JSON 解析还是 URLSession 报错。
enum APIClientError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(String)
    case server(code: Int, msg: String)
    case network(underlying: URLError)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效"
        case .invalidResponse(let detail):
            return "服务端响应异常：\(detail)"
        case .server(_, let msg):
            return msg
        case .network(let underlying):
            switch underlying.code {
            case .networkConnectionLost:
                return "网络连接中断，请稍后重试"
            case .notConnectedToInternet:
                return "当前无网络连接"
            case .timedOut:
                return "请求超时，请检查网络后重试"
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "无法连接服务器，请稍后重试"
            default:
                return underlying.localizedDescription
            }
        }
    }
}

final class APIClient {
    // 全局单例：当前 App 网络请求很少，用一个客户端即可复用 URLSession 配置。
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        // URLSession 配置集中在这里，后续如果要调超时时间或缓存策略，只改这一处。
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.urlCache = URLCache(
            memoryCapacity: 40 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "badup-urlcache"
        )
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
    }

    // 用设备唯一标识自动登录或注册。
    // 启动页会调用它，成功后服务端返回 bad_User 里的用户信息。
    func loginOrRegisterByDeviceId() async throws -> BadUpUser {
        let deviceId = persistentDeviceId()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let systemVersion = UIDevice.current.systemVersion

        let payload: [String: Any?] = [
            "deviceId": deviceId,
            "platform": "iOS",
            "appVersion": appVersion,
            "systemVersion": systemVersion
        ]

        let url = BadUpAPI.baseURL.appendingPathComponent("bad_UserLoginRegister.php")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let body = payload.compactMapValues { $0 }
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        // 登录接口对启动体验很关键，所以只对网络抖动做短暂重试。
        // HTTP 5xx 不在这里重试，避免服务器压力大时客户端反复打接口。
        let (data, response) = try await dataWithRetry(for: request, maxAttempts: 3)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse("不是 HTTP 响应")
        }

        let responseText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.invalidResponse("HTTP \(httpResponse.statusCode)，\(responseText)")
        }

        // 服务端偶尔会返回 text/plain（例如数据库连接失败），这里优先给出更明确的提示。
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           !contentType.lowercased().contains("application/json") {
            throw APIClientError.server(code: httpResponse.statusCode, msg: "服务端返回非 JSON：\(contentType)，\(responseText)")
        }

        let apiResponse: BadUpAPIResponse<BadUpUser>
        do {
            apiResponse = try decoder.decode(BadUpAPIResponse<BadUpUser>.self, from: data)
        } catch {
            throw APIClientError.server(code: httpResponse.statusCode, msg: "JSON 解析失败：\(responseText)")
        }
        guard apiResponse.code == 200 else {
            throw APIClientError.server(code: apiResponse.code, msg: apiResponse.msg)
        }
        guard let user = apiResponse.data else {
            throw APIClientError.invalidResponse("缺少 data 字段，\(responseText)")
        }
        return user
    }

    // 对可恢复的网络错误做指数退避重试。
    // 这里不处理业务错误，业务错误由接口 JSON 的 code/msg 决定。
    private func dataWithRetry(for request: URLRequest, maxAttempts: Int) async throws -> (Data, URLResponse) {
        precondition(maxAttempts >= 1)

        var attempt = 0
        while true {
            attempt += 1
            do {
                let result = try await session.data(for: request)
                return result
            } catch {
                let nsError = error as NSError
                let urlError = (error as? URLError) ?? (nsError.userInfo[NSUnderlyingErrorKey] as? URLError)
                if let urlError, shouldRetry(urlError), attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: retryDelayNanoseconds(for: attempt))
                    continue
                }
                if let urlError {
                    throw APIClientError.network(underlying: urlError)
                }
                throw error
            }
        }
    }

    // 每次失败后稍微等久一点再重试，避免瞬间连续请求。
    private func retryDelayNanoseconds(for attempt: Int) -> UInt64 {
        let backoffSeconds = min(pow(2.0, Double(attempt - 1)) * 0.6, 3.0)
        return UInt64(backoffSeconds * 1_000_000_000)
    }

    // 只重试明显可能是临时网络问题的错误。
    private func shouldRetry(_ error: URLError) -> Bool {
        switch error.code {
        case .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    // 设备标识统一从 Keychain 获取，保证删除 App 后再装仍尽量保持同一用户。
    private func persistentDeviceId() -> String {
        DeviceIdentityStore.deviceId()
    }
}
