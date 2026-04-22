import Foundation

// 服务端统一响应结构。
// PHP 接口固定返回 code/msg，部分接口还会返回 data。
struct BadUpAPIResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T?
}

// 服务端 bad_User 表对应的客户端模型。
// 字段保持和 MySQL/PHP 返回的 lower camel 命名一致，避免额外映射。
struct BadUpUser: Codable, Equatable {
    let userId: Int
    let userCode: String?
    let userName: String?
    let phone: String?
    let email: String?
    let avatar: String?
    let deviceId: String?
    let platform: String?
    let appVersion: String?
    let systemVersion: String?
    let ip: String?
    let status: Int?
    let createdAt: String?
    let updatedAt: String?

    init(
        userId: Int,
        userCode: String?,
        userName: String?,
        phone: String?,
        email: String?,
        avatar: String?,
        deviceId: String?,
        platform: String?,
        appVersion: String?,
        systemVersion: String?,
        ip: String?,
        status: Int?,
        createdAt: String?,
        updatedAt: String?
    ) {
        self.userId = userId
        self.userCode = userCode
        self.userName = userName
        self.phone = phone
        self.email = email
        self.avatar = avatar
        self.deviceId = deviceId
        self.platform = platform
        self.appVersion = appVersion
        self.systemVersion = systemVersion
        self.ip = ip
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension BadUpUser {
    enum CodingKeys: String, CodingKey {
        case userId
        case userCode
        case userName
        case phone
        case email
        case avatar
        case deviceId
        case platform
        case appVersion
        case systemVersion
        case ip
        case status
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // MySQL/PDO 有时会把数字字段返回成字符串，这里兼容 Int 和 "10001" 两种格式。
        func decodeIntLenient(_ key: CodingKeys) throws -> Int {
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue
            }
            let stringValue = try container.decode(String.self, forKey: key)
            if let intValue = Int(stringValue) {
                return intValue
            }
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected Int or numeric String")
        }

        // 可选数字字段也做同样兼容，避免服务端返回字符串时解析失败。
        func decodeOptionalIntLenient(_ key: CodingKeys) -> Int? {
            if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                return intValue
            }
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
                return Int(stringValue)
            }
            return nil
        }

        self.init(
            userId: try decodeIntLenient(.userId),
            userCode: try container.decodeIfPresent(String.self, forKey: .userCode),
            userName: try container.decodeIfPresent(String.self, forKey: .userName),
            phone: try container.decodeIfPresent(String.self, forKey: .phone),
            email: try container.decodeIfPresent(String.self, forKey: .email),
            avatar: try container.decodeIfPresent(String.self, forKey: .avatar),
            deviceId: try container.decodeIfPresent(String.self, forKey: .deviceId),
            platform: try container.decodeIfPresent(String.self, forKey: .platform),
            appVersion: try container.decodeIfPresent(String.self, forKey: .appVersion),
            systemVersion: try container.decodeIfPresent(String.self, forKey: .systemVersion),
            ip: try container.decodeIfPresent(String.self, forKey: .ip),
            status: decodeOptionalIntLenient(.status),
            createdAt: try container.decodeIfPresent(String.self, forKey: .createdAt),
            updatedAt: try container.decodeIfPresent(String.self, forKey: .updatedAt)
        )
    }
}
