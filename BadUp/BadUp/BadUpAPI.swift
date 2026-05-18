import Foundation

// 后端接口地址配置。
// 所有 Swift 网络请求都从这里拼接 PHP 文件名，换服务器时优先改这里。
enum BadUpAPI {
    static let baseURL: URL = {
        // 末尾必须保留 /phpBadUp/，否则 appendingPathComponent 会拼错接口路径。
        URL(string: "https://55shouzhuan.com/phpBadUp/")!
    }()
}
