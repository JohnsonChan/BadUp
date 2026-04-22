import Foundation
import Security
import UIKit

// 设备唯一标识存储。
// identifierForVendor 在删除 App 后可能变化，所以这里把首次生成的值写入 Keychain。
// Keychain 通常不会随 App 删除一起清掉，能更稳定地识别同一台 iPhone。
enum DeviceIdentityStore {
    private static let service = "ai.xiaolang.BadUp.device"
    private static let account = "deviceId"
    private static let legacyUserDefaultsKey = "badup.device.id"

    // 获取当前设备 ID：优先 Keychain，其次兼容旧版 UserDefaults，最后才新生成。
    static func deviceId() -> String {
        if let existing = readFromKeychain(), !existing.isEmpty {
            return existing
        }

        if let legacy = UserDefaults.standard.string(forKey: legacyUserDefaultsKey), !legacy.isEmpty {
            saveToKeychain(legacy)
            return legacy
        }

        let newValue = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveToKeychain(newValue)
        UserDefaults.standard.set(newValue, forKey: legacyUserDefaultsKey)
        return newValue
    }

    // 从 Keychain 读取已保存的设备 ID。
    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // 写入或更新 Keychain。
    // kSecAttrAccessibleAfterFirstUnlock 让设备首次解锁后后台也能读取。
    private static func saveToKeychain(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
