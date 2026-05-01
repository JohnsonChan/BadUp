import SwiftUI

// App 的根视图。
// 先显示 SplashView 完成自动登录；登录成功后再进入 ContentView。
struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var didShowMinimumSplash = false

    private var canEnterApp: Bool {
        didShowMinimumSplash && session.didFinishLaunchLogin && session.user != nil
    }

    var body: some View {
        Group {
            // 同时满足“登录完成”和“闪屏至少展示 1 秒”后才进入主界面。
            if canEnterApp {
                ContentView()
            } else {
                SplashView()
            }
        }
        .task {
            // 即使服务器瞬间返回，也让启动页停留一下，避免画面一闪而过。
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            didShowMinimumSplash = true
        }
    }
}
