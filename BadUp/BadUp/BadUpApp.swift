//
//  BadUpApp.swift
//  BadUp
//
//  Created by chenrs on 2026/4/16.
//

import SwiftUI

@main
// App 入口。
// 程序启动后会从这里创建主窗口，并把 `ContentView` 作为首页显示出来。
struct BadUpApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}
