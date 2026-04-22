import SwiftUI
import UIKit
import Combine

@MainActor
// 远程图片加载器。
// 目前启动页已改成本地绘制背景，这个组件保留给后续如果要加载远程头像/图片使用。
final class RemoteImageLoader: ObservableObject {
    @Published var image: Image?
    @Published var isLoading: Bool = false

    private var currentURL: URL?

    // 加载图片：先读磁盘缓存，缓存没有再走网络。
    func load(from url: URL) {
        guard currentURL != url else { return }
        currentURL = url

        if let data = RemoteImageCache.shared.cachedData(for: url),
           let uiImage = UIImage(data: data) {
            image = Image(uiImage: uiImage)
            return
        }

        isLoading = true
        image = nil

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                RemoteImageCache.shared.store(data, for: url)
                if let uiImage = UIImage(data: data) {
                    image = Image(uiImage: uiImage)
                }
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}

// 带磁盘缓存的远程图片 View。
// 使用时只需要传 URL 和 contentMode，内部负责加载、缓存和占位背景。
struct CachedRemoteImageView: View {
    let url: URL
    let contentMode: ContentMode

    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.10))
            }
        }
        .onAppear {
            loader.load(from: url)
        }
    }
}
