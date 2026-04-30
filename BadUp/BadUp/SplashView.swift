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
                        Color(red: 0.98, green: 1.00, blue: 0.98),
                        Color(red: 0.93, green: 0.98, blue: 0.94),
                        Color(red: 0.85, green: 0.95, blue: 0.89)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color(red: 0.34, green: 0.78, blue: 0.50).opacity(0.16))
                    .frame(width: 180, height: 180)
                    .blur(radius: 14)
                    .position(x: 32, y: proxy.size.height * 0.20)

                Circle()
                    .fill(Color(red: 0.09, green: 0.63, blue: 0.52).opacity(0.14))
                    .frame(width: 170, height: 170)
                    .blur(radius: 14)
                    .position(x: proxy.size.width - 24, y: proxy.size.height * 0.78)

                VStack(spacing: 14) {
                    Text("芽记")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(Color(red: 0.09, green: 0.23, blue: 0.18))

                    VStack(spacing: 5) {
                        Text("记录好习惯，然后成长一点")
                        Text("记录坏习惯，然后少做一点")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.09, green: 0.23, blue: 0.18).opacity(0.72))
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)

                VStack(spacing: 12) {
                    // 三种状态：登录中、登录失败、等待 onAppear 开始登录。
                    if session.isLoading {
                        ProgressView()
                            .tint(Color(red: 0.22, green: 0.63, blue: 0.40))
                        Text("正在登录…")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 0.13, green: 0.31, blue: 0.25))
                    } else if let error = session.errorMessage {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 0.13, green: 0.31, blue: 0.25))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)

                        Button("重试") {
                            session.retry()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.24, green: 0.71, blue: 0.43))
                        .foregroundStyle(.white)
                    } else {
                        ProgressView()
                            .tint(Color(red: 0.22, green: 0.63, blue: 0.40))
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
