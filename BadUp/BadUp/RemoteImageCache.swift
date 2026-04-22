import Foundation
import CryptoKit

// 简单的磁盘图片缓存。
// URL 会被 SHA256 成文件名，避免特殊字符导致路径不可用。
final class RemoteImageCache {
    static let shared = RemoteImageCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // 缓存放在系统 Caches 目录，iOS 空间紧张时可以安全清理。
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = base.appendingPathComponent("badup-remote-images", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // 读取某个 URL 对应的本地缓存数据。
    func cachedData(for url: URL) -> Data? {
        let path = cacheDirectory.appendingPathComponent(fileName(for: url))
        return try? Data(contentsOf: path)
    }

    // 把网络下载的数据写入缓存。
    func store(_ data: Data, for url: URL) {
        let path = cacheDirectory.appendingPathComponent(fileName(for: url))
        try? data.write(to: path, options: [.atomic])
    }

    // 用 URL 字符串生成稳定文件名。
    private func fileName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
