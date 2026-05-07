import Foundation
import Combine

// 单条记录被删除后，用这个轻量变更对象通知统计页刷新。
struct BehaviorRecordStatsChange: Equatable {
    let token: Int
    let behaviorId: Int64
    let year: Int
    let month: Int
    let recordDate: String
}

@MainActor
// 全局登录状态。
// RootView、SplashView、ContentView 都通过 EnvironmentObject 读取这里的用户状态。
final class SessionStore: ObservableObject {
    // 登录成功后的服务端用户信息。
    @Published private(set) var user: BadUpUser?
    // 标记启动登录流程是否结束；只有结束且 user 不为空时才进入主界面。
    @Published private(set) var didFinishLaunchLogin: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var behaviorRecordStatsChange: BehaviorRecordStatsChange?

    // 缓存最近一次用户信息，便于“更多”页先展示上次登录信息。
    private let userDefaultsKey = "badup.session.user"

    init() {
        loadCachedUser()
    }

    // 启动页调用：如果当前还没有登录流程，就自动用设备标识登录/注册。
    func startLoginIfNeeded() {
        guard !isLoading, !didFinishLaunchLogin else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loggedInUser = try await APIClient.shared.loginOrRegisterByDeviceId()
                user = loggedInUser
                cache(user: loggedInUser)
                didFinishLaunchLogin = true
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // 启动页“重试”按钮调用。
    func retry() {
        didFinishLaunchLogin = false
        startLoginIfNeeded()
    }

    // 日期页删除单条记录成功后调用。
    // 月页和年页只在 token 变化且范围匹配时刷新，避免无删除动作也重复请求。
    func markBehaviorRecordStatsChanged(behaviorId: Int64, date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        behaviorRecordStatsChange = BehaviorRecordStatsChange(
            token: (behaviorRecordStatsChange?.token ?? 0) + 1,
            behaviorId: behaviorId,
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            recordDate: formatter.string(from: date)
        )
    }

    // 登录成功后缓存用户信息。缓存失败不影响真实登录态，所以 catch 里不弹错。
    private func cache(user: BadUpUser) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // 忽略缓存失败，不影响登录态
        }
    }

    // App 启动时先恢复本地缓存，随后仍会走服务端登录拿最新用户信息。
    private func loadCachedUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        guard let cached = try? JSONDecoder().decode(BadUpUser.self, from: data) else { return }
        self.user = cached
    }
}
