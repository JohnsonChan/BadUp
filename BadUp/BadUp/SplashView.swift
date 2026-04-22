import SwiftUI

// 启动页。
// 这里不只是展示 Logo，也负责触发“自动登录/注册”流程。
struct SplashView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        // 用 GeometryReader 计算位置，保证不同分辨率设备上标题和按钮区域比例一致。
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.10, blue: 0.19),
                        Color(red: 0.24, green: 0.10, blue: 0.16),
                        Color(red: 0.40, green: 0.14, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 14) {
                    Text("坏是做尽")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("记录坏习惯，然后少做一点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)

                VStack(spacing: 12) {
                    // 三种状态：登录中、登录失败、等待 onAppear 开始登录。
                    if session.isLoading {
                        ProgressView()
                            .tint(.white)
                        Text("正在登录…")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                    } else if let error = session.errorMessage {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)

                        Button("重试") {
                            session.retry()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white.opacity(0.92))
                        .foregroundStyle(.black)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.72)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            // 页面出现时启动登录；SessionStore 内部会避免重复请求。
            session.startLoginIfNeeded()
        }
    }
}
