//
//  ContentView.swift
//  BadUp
//
//  Created by chenrs on 2026/4/16.
//

import SwiftUI
import Combine
import SQLite3

// 定义 App 里可以记录的坏习惯类型。
// `CaseIterable` 让我们可以直接遍历所有行为来生成按钮和统计列表。
// `Identifiable` 让 SwiftUI 的 `ForEach` 可以稳定识别每一项。
private enum BehaviorType: String, CaseIterable, Identifiable {
    case masturbation = "撸管"
    case shortVideo = "刷视频"
    case stayingUpLate = "熬夜"
    case overeating = "吃太饱"

    // 把中文名称作为唯一标识，方便 SwiftUI 列表使用。
    var id: String { rawValue }

    // 按钮上显示的标题。
    var buttonTitle: String {
        rawValue
    }
}

// 表示“某一天里某种行为的统计结果”。
// 这个结构体主要给界面展示使用。
private struct DailyBehaviorCount: Identifiable {
    let behavior: BehaviorType
    var count: Int

    // 用行为类型本身作为列表 id。
    var id: String { behavior.id }
}

// 负责和 SQLite 数据库打交道。
// 这里把建表、插入、查询都封装起来，界面层只需要调用方法即可。
private final class BehaviorDatabase {
    // SQLite 原生数据库连接指针。
    private var db: OpaquePointer?

    // 统一把日期格式化成 yyyy-MM-dd，确保“按天”存储时规则一致。
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // 初始化时先打开数据库，再确保表已经创建好。
    init() {
        openDatabase()
        createTableIfNeeded()
    }

    // 对象释放时关闭数据库连接，避免资源泄漏。
    deinit {
        sqlite3_close(db)
    }

    // 插入一条新的行为记录。
    // 每点一次确认，就写入一条 count = 1 的记录。
    func insertRecord(for behavior: BehaviorType, on date: Date = Date()) {
        let sql = "INSERT INTO behavior_records (record_date, behavior_type, count) VALUES (?, ?, 1);"
        var statement: OpaquePointer?

        // 先把 SQL 编译成可执行语句。
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("insert prepare failed")
            return
        }

        // 函数结束前释放 statement。
        defer { sqlite3_finalize(statement) }

        // 把日期和行为类型绑定到 SQL 占位符上。
        let dateString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (behavior.rawValue as NSString).utf8String, -1, nil)

        // 真正执行插入。
        if sqlite3_step(statement) != SQLITE_DONE {
            print("insert step failed")
        }
    }

    // 查询今天每种行为的总次数。
    // 即使某项今天还没有记录，也会返回 0，保证界面始终显示完整四项。
    func fetchTodayCounts(on date: Date = Date()) -> [DailyBehaviorCount] {
        let sql = """
        SELECT behavior_type, SUM(count)
        FROM behavior_records
        WHERE record_date = ?
        GROUP BY behavior_type;
        """
        var statement: OpaquePointer?

        // 先默认所有行为都是 0 次，后面再用查询结果覆盖。
        var counts = Dictionary(uniqueKeysWithValues: BehaviorType.allCases.map { ($0, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetch prepare failed")
            return BehaviorType.allCases.map { DailyBehaviorCount(behavior: $0, count: 0) }
        }

        defer { sqlite3_finalize(statement) }

        // 绑定今天的日期，只查今天的数据。
        let dateString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)

        // 逐行读取查询结果，并写回到字典里。
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let behaviorTypeCString = sqlite3_column_text(statement, 0),
                let behavior = BehaviorType(rawValue: String(cString: behaviorTypeCString))
            else {
                continue
            }

            counts[behavior] = Int(sqlite3_column_int(statement, 1))
        }

        // 按固定顺序返回，保证界面展示顺序稳定。
        return BehaviorType.allCases.map {
            DailyBehaviorCount(behavior: $0, count: counts[$0, default: 0])
        }
    }

    // 打开位于 Documents 目录中的 SQLite 文件。
    private func openDatabase() {
        let fileURL = Self.databaseURL()
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("open database failed")
        }
    }

    // 如果表不存在就创建一张记录表。
    // 每条记录保存：日期、行为类型、次数。
    private func createTableIfNeeded() {
        let sql = """
        CREATE TABLE IF NOT EXISTS behavior_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_date TEXT NOT NULL,
            behavior_type TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 1
        );
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("create table failed")
        }
    }

    // 数据库文件的保存路径。
    private static func databaseURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("behavior_records.sqlite")
    }
}

@MainActor
// 视图模型：负责连接界面和数据库。
// 界面按钮触发它，数据变化后通过 `@Published` 自动刷新 SwiftUI。
private final class ContentViewModel: ObservableObject {
    // 保存“今天”的统计结果，界面会自动订阅它的变化。
    @Published var todayCounts: [DailyBehaviorCount] = BehaviorType.allCases.map {
        DailyBehaviorCount(behavior: $0, count: 0)
    }

    // 数据库实例只在 ViewModel 内部使用。
    private let database = BehaviorDatabase()

    // 页面创建时先加载一次今天的数据。
    init() {
        loadTodayCounts()
    }

    // 记录一次行为，然后重新读取今天统计，让页面数字马上更新。
    func record(_ behavior: BehaviorType) {
        database.insertRecord(for: behavior)
        loadTodayCounts()
    }

    // 从数据库重新读取今天所有行为的次数。
    func loadTodayCounts() {
        todayCounts = database.fetchTodayCounts()
    }
}

// 主页面。
struct ContentView: View {
    // 页面生命周期内持有同一个 ViewModel。
    @StateObject private var viewModel = ContentViewModel()

    // 用来记录“当前准备确认的行为”。
    // 不为 nil 时，弹出确认框。
    @State private var pendingBehavior: BehaviorType?

    // 页面顶部显示的今天日期文本。
    private let dateText: String = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: Date())
    }()

    var body: some View {
        // 整体页面上下排布：标题、按钮区、统计区。
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("今日行为记录")
                    .font(.largeTitle.bold())
                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                // 遍历所有行为，自动生成按钮。
                ForEach(BehaviorType.allCases) { behavior in
                    Button {
                        // 点击后先不直接写库，而是先弹确认框。
                        pendingBehavior = behavior
                    } label: {
                        Text(behavior.buttonTitle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("今天统计")
                    .font(.headline)

                // 展示今天每一种行为的累计次数。
                ForEach(viewModel.todayCounts) { item in
                    HStack {
                        Text(item.behavior.rawValue)
                        Spacer()
                        Text("\(item.count) 次")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // 页面出现时再刷新一次，避免从后台回来时数据过旧。
            viewModel.loadTodayCounts()
        }
        // 统一的确认弹窗。
        // 只有在 `pendingBehavior` 有值时才会弹出。
        .alert(
            "确认记录",
            isPresented: Binding(
                get: { pendingBehavior != nil },
                set: { isPresented in
                    // 弹窗被关闭时，顺手清掉待确认状态。
                    if !isPresented {
                        pendingBehavior = nil
                    }
                }
            ),
            presenting: pendingBehavior
        ) { behavior in
            Button("取消", role: .cancel) {
                pendingBehavior = nil
            }
            Button("确认") {
                // 用户确认后，才真正增加一次记录。
                viewModel.record(behavior)
                pendingBehavior = nil
            }
        } message: { behavior in
            // 根据点击的行为动态生成提示文案。
            Text("确定要记录一次\(behavior.rawValue)吗？")
        }
    }
}

// Xcode 预览。
#Preview {
    ContentView()
}
