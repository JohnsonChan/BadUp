//
//  ContentView.swift
//  BadUp
//
//  Created by chenrs on 2026/4/16.
//

import SwiftUI
import Combine
import SQLite3

// 更丰富的颜色板项。
// 这些颜色会在“更多颜色”弹层中展示。
private struct ColorPaletteItem: Identifiable, Hashable {
    let hex: String
    let name: String
    let color: Color

    var id: String { hex }
}

// 可选的行为颜色。
// 这里用预设颜色而不是自由取色，能让按钮和统计页风格保持整齐。
private enum BehaviorColorOption: String, CaseIterable, Identifiable {
    case coral = "#F55F52"
    case orange = "#F9B536"
    case cyan = "#31B3C5"
    case blue = "#6C7EF7"
    case green = "#43C77A"
    case pink = "#F56EA4"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .coral:
            return Color(red: 0.96, green: 0.37, blue: 0.32)
        case .orange:
            return Color(red: 0.98, green: 0.71, blue: 0.21)
        case .cyan:
            return Color(red: 0.19, green: 0.70, blue: 0.77)
        case .blue:
            return Color(red: 0.42, green: 0.49, blue: 0.97)
        case .green:
            return Color(red: 0.26, green: 0.78, blue: 0.48)
        case .pink:
            return Color(red: 0.96, green: 0.43, blue: 0.64)
        }
    }

    var name: String {
        switch self {
        case .coral: return "珊瑚红"
        case .orange: return "橙黄"
        case .cyan: return "湖蓝"
        case .blue: return "钴蓝"
        case .green: return "薄荷绿"
        case .pink: return "粉红"
        }
    }

    static func from(hex: String) -> BehaviorColorOption {
        BehaviorColorOption(rawValue: hex) ?? .coral
    }
}

private extension Array where Element == ColorPaletteItem {
    static let extendedBehaviorPalette: [ColorPaletteItem] = [
        ColorPaletteItem(hex: "#F55F52", name: "珊瑚红", color: Color(red: 0.96, green: 0.37, blue: 0.32)),
        ColorPaletteItem(hex: "#F9B536", name: "橙黄", color: Color(red: 0.98, green: 0.71, blue: 0.21)),
        ColorPaletteItem(hex: "#31B3C5", name: "湖蓝", color: Color(red: 0.19, green: 0.70, blue: 0.77)),
        ColorPaletteItem(hex: "#6C7EF7", name: "钴蓝", color: Color(red: 0.42, green: 0.49, blue: 0.97)),
        ColorPaletteItem(hex: "#43C77A", name: "薄荷绿", color: Color(red: 0.26, green: 0.78, blue: 0.48)),
        ColorPaletteItem(hex: "#F56EA4", name: "粉红", color: Color(red: 0.96, green: 0.43, blue: 0.64)),
        ColorPaletteItem(hex: "#8C5CF6", name: "紫罗兰", color: Color(red: 0.55, green: 0.36, blue: 0.96)),
        ColorPaletteItem(hex: "#A66A43", name: "焦糖棕", color: Color(red: 0.65, green: 0.42, blue: 0.26)),
        ColorPaletteItem(hex: "#16A085", name: "青绿", color: Color(red: 0.09, green: 0.63, blue: 0.52)),
        ColorPaletteItem(hex: "#D35400", name: "南瓜橙", color: Color(red: 0.83, green: 0.33, blue: 0.00)),
        ColorPaletteItem(hex: "#C0392B", name: "砖红", color: Color(red: 0.75, green: 0.22, blue: 0.17)),
        ColorPaletteItem(hex: "#2C3E50", name: "深海军蓝", color: Color(red: 0.17, green: 0.24, blue: 0.31)),
        ColorPaletteItem(hex: "#7F8C8D", name: "石墨灰", color: Color(red: 0.50, green: 0.55, blue: 0.55)),
        ColorPaletteItem(hex: "#27AE60", name: "森林绿", color: Color(red: 0.15, green: 0.68, blue: 0.38)),
        ColorPaletteItem(hex: "#E84393", name: "洋红", color: Color(red: 0.91, green: 0.26, blue: 0.58)),
        ColorPaletteItem(hex: "#00A8FF", name: "天空蓝", color: Color(red: 0.00, green: 0.66, blue: 1.00)),
        ColorPaletteItem(hex: "#F1C40F", name: "明黄", color: Color(red: 0.95, green: 0.77, blue: 0.06)),
        ColorPaletteItem(hex: "#6D214F", name: "酒红", color: Color(red: 0.43, green: 0.13, blue: 0.31))
    ]
}

// 行为项模型。
// 默认行为和用户新增行为都统一走这个结构。
private struct BehaviorItem: Identifiable, Hashable {
    let id: Int64
    let name: String
    let detail: String
    let colorHex: String

    var tintColor: Color {
        if let paletteItem = Array.extendedBehaviorPalette.first(where: { $0.hex == colorHex }) {
            return paletteItem.color
        }
        return BehaviorColorOption.from(hex: colorHex).color
    }
}

// 首页里“今天统计”的单项。
private struct DailyBehaviorCount: Identifiable {
    let behavior: BehaviorItem
    var count: Int

    var id: Int64 { behavior.id }
}

// 年/月/日视图的统计结构。
private struct MonthSummary: Identifiable {
    let month: Int
    var count: Int
    var id: Int { month }
}

private struct DaySummary: Identifiable {
    let date: Date
    let day: Int
    var count: Int
    var id: Date { date }
}

private struct HourSummary: Identifiable {
    let hour: Int
    var count: Int

    var id: Int { hour }

    var hourText: String {
        String(format: "%02d:00", hour)
    }
}

// SQLite 数据库封装。
// 这里同时管理“行为表”和“记录表”。
private final class BehaviorDatabase {
    private var db: OpaquePointer?

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private let recordedAtExpression = "COALESCE(recorded_at, record_date || ' 12:00:00')"

    init() {
        openDatabase()
        createBehaviorTableIfNeeded()
        createRecordTableIfNeeded()
        addRecordedAtColumnIfNeeded()
        seedDefaultBehaviors()
    }

    deinit {
        sqlite3_close(db)
    }

    // 读取所有行为项，按创建顺序展示。
    func fetchBehaviors() -> [BehaviorItem] {
        let sql = """
        SELECT id, name, detail, color_hex
        FROM behaviors
        ORDER BY id ASC;
        """
        var statement: OpaquePointer?
        var items: [BehaviorItem] = []

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetch behaviors prepare failed")
            return []
        }

        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let name = String(cString: sqlite3_column_text(statement, 1))
            let detail = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let colorHex = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? BehaviorColorOption.coral.rawValue
            items.append(BehaviorItem(id: id, name: name, detail: detail, colorHex: colorHex))
        }

        return items
    }

    // 新增自定义行为项。
    func addBehavior(name: String, detail: String, colorHex: String) -> Bool {
        let sql = """
        INSERT INTO behaviors (name, detail, color_hex)
        VALUES (?, ?, ?);
        """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("add behavior prepare failed")
            return false
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (detail as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (colorHex as NSString).utf8String, -1, nil)

        return sqlite3_step(statement) == SQLITE_DONE
    }

    // 删除行为项，同时把它的历史记录一并删除。
    func deleteBehavior(id: Int64) -> Bool {
        guard let behavior = fetchBehaviors().first(where: { $0.id == id }) else {
            return false
        }

        let deleteRecordsSQL = "DELETE FROM behavior_records WHERE behavior_type = ?;"
        var deleteRecordsStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, deleteRecordsSQL, -1, &deleteRecordsStatement, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_text(deleteRecordsStatement, 1, (behavior.name as NSString).utf8String, -1, nil)
        let recordsDeleted = sqlite3_step(deleteRecordsStatement) == SQLITE_DONE
        sqlite3_finalize(deleteRecordsStatement)

        guard recordsDeleted else {
            return false
        }

        let deleteBehaviorSQL = "DELETE FROM behaviors WHERE id = ?;"
        var deleteBehaviorStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, deleteBehaviorSQL, -1, &deleteBehaviorStatement, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int64(deleteBehaviorStatement, 1, id)
        let behaviorDeleted = sqlite3_step(deleteBehaviorStatement) == SQLITE_DONE
        sqlite3_finalize(deleteBehaviorStatement)

        return behaviorDeleted
    }

    // 写入一次行为记录。
    func insertRecord(for behavior: BehaviorItem, on date: Date = Date()) {
        let sql = """
        INSERT INTO behavior_records (record_date, recorded_at, behavior_type, count)
        VALUES (?, ?, ?, 1);
        """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("insert prepare failed")
            return
        }

        defer { sqlite3_finalize(statement) }

        let dateString = dateFormatter.string(from: date)
        let dateTimeString = dateTimeFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (dateTimeString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (behavior.name as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("insert step failed")
        }
    }

    // 查询今天所有行为的次数。
    func fetchTodayCounts(for behaviors: [BehaviorItem], on date: Date = Date()) -> [DailyBehaviorCount] {
        let sql = """
        SELECT behavior_type, SUM(count)
        FROM behavior_records
        WHERE record_date = ?
        GROUP BY behavior_type;
        """
        var statement: OpaquePointer?
        var counts = Dictionary(uniqueKeysWithValues: behaviors.map { ($0.name, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetch today prepare failed")
            return behaviors.map { DailyBehaviorCount(behavior: $0, count: 0) }
        }

        defer { sqlite3_finalize(statement) }

        let dateString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let behaviorTypeCString = sqlite3_column_text(statement, 0) else {
                continue
            }
            let name = String(cString: behaviorTypeCString)
            counts[name] = Int(sqlite3_column_int(statement, 1))
        }

        return behaviors.map { DailyBehaviorCount(behavior: $0, count: counts[$0.name, default: 0]) }
    }

    func fetchMonthSummaries(for behavior: BehaviorItem, year: Int) -> [MonthSummary] {
        let sql = """
        SELECT CAST(strftime('%m', \(recordedAtExpression)) AS INTEGER), SUM(count)
        FROM behavior_records
        WHERE behavior_type = ?
          AND CAST(strftime('%Y', \(recordedAtExpression)) AS INTEGER) = ?
        GROUP BY 1
        ORDER BY 1;
        """
        var statement: OpaquePointer?
        var counts = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("year summary prepare failed")
            return (1...12).map { MonthSummary(month: $0, count: 0) }
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (behavior.name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(year))

        while sqlite3_step(statement) == SQLITE_ROW {
            counts[Int(sqlite3_column_int(statement, 0))] = Int(sqlite3_column_int(statement, 1))
        }

        return (1...12).map { MonthSummary(month: $0, count: counts[$0, default: 0]) }
    }

    func fetchDaySummaries(for behavior: BehaviorItem, year: Int, month: Int) -> [DaySummary] {
        guard
            let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let dayRange = calendar.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        let sql = """
        SELECT CAST(strftime('%d', \(recordedAtExpression)) AS INTEGER), SUM(count)
        FROM behavior_records
        WHERE behavior_type = ?
          AND strftime('%Y', \(recordedAtExpression)) = ?
          AND strftime('%m', \(recordedAtExpression)) = ?
        GROUP BY 1
        ORDER BY 1;
        """
        var statement: OpaquePointer?
        var counts = Dictionary(uniqueKeysWithValues: dayRange.map { ($0, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("month summary prepare failed")
            return dayRange.compactMap { day in
                calendar.date(from: DateComponents(year: year, month: month, day: day)).map {
                    DaySummary(date: $0, day: day, count: 0)
                }
            }
        }

        defer { sqlite3_finalize(statement) }

        let yearString = String(format: "%04d", year)
        let monthString = String(format: "%02d", month)
        sqlite3_bind_text(statement, 1, (behavior.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (yearString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (monthString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            counts[Int(sqlite3_column_int(statement, 0))] = Int(sqlite3_column_int(statement, 1))
        }

        return dayRange.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day)).map {
                DaySummary(date: $0, day: day, count: counts[day, default: 0])
            }
        }
    }

    func fetchHourSummaries(for behavior: BehaviorItem, date: Date) -> [HourSummary] {
        let sql = """
        SELECT CAST(strftime('%H', \(recordedAtExpression)) AS INTEGER), SUM(count)
        FROM behavior_records
        WHERE behavior_type = ?
          AND strftime('%Y-%m-%d', \(recordedAtExpression)) = ?
        GROUP BY 1
        ORDER BY 1;
        """
        var statement: OpaquePointer?
        var counts = Dictionary(uniqueKeysWithValues: (0...23).map { ($0, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("day summary prepare failed")
            return (0...23).map { HourSummary(hour: $0, count: 0) }
        }

        defer { sqlite3_finalize(statement) }

        let dayString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (behavior.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (dayString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            counts[Int(sqlite3_column_int(statement, 0))] = Int(sqlite3_column_int(statement, 1))
        }

        return (0...23).map { HourSummary(hour: $0, count: counts[$0, default: 0]) }
    }

    private func openDatabase() {
        let fileURL = Self.databaseURL()
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("open database failed")
        }
    }

    private func createBehaviorTableIfNeeded() {
        let sql = """
        CREATE TABLE IF NOT EXISTS behaviors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            detail TEXT NOT NULL DEFAULT '',
            color_hex TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("create behaviors table failed")
        }
    }

    private func createRecordTableIfNeeded() {
        let sql = """
        CREATE TABLE IF NOT EXISTS behavior_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_date TEXT NOT NULL,
            recorded_at TEXT,
            behavior_type TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 1
        );
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("create records table failed")
        }
    }

    private func addRecordedAtColumnIfNeeded() {
        let sql = "ALTER TABLE behavior_records ADD COLUMN recorded_at TEXT;"
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // 首次运行时写入默认的 4 个行为项。
    private func seedDefaultBehaviors() {
        let defaults: [(String, String, String)] = [
            ("撸管", "记录冲动型坏习惯", BehaviorColorOption.coral.rawValue),
            ("刷视频", "记录无意识刷短视频", BehaviorColorOption.orange.rawValue),
            ("熬夜", "记录晚睡和拖延入睡", BehaviorColorOption.cyan.rawValue),
            ("吃太饱", "记录暴食或吃撑的情况", BehaviorColorOption.blue.rawValue)
        ]

        for item in defaults {
            let sql = """
            INSERT OR IGNORE INTO behaviors (name, detail, color_hex)
            VALUES (?, ?, ?);
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                continue
            }

            sqlite3_bind_text(statement, 1, (item.0 as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (item.1 as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (item.2 as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

    private static func databaseURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("behavior_records.sqlite")
    }
}

@MainActor
// 首页视图模型：负责行为列表和今天统计。
private final class ContentViewModel: ObservableObject {
    @Published var behaviors: [BehaviorItem] = []
    @Published var todayCounts: [DailyBehaviorCount] = []
    @Published var addBehaviorErrorMessage: String?

    private let database = BehaviorDatabase()

    init() {
        loadAll()
    }

    func loadAll() {
        let items = database.fetchBehaviors()
        behaviors = items
        todayCounts = database.fetchTodayCounts(for: items)
    }

    func record(_ behavior: BehaviorItem) {
        database.insertRecord(for: behavior)
        loadAll()
    }

    func addBehavior(name: String, detail: String, colorHex: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            addBehaviorErrorMessage = "行为名称不能为空"
            return false
        }

        if behaviors.contains(where: { $0.name == trimmedName }) {
            addBehaviorErrorMessage = "已经存在同名行为，请换一个名称"
            return false
        }

        let success = database.addBehavior(name: trimmedName, detail: trimmedDetail, colorHex: colorHex)
        if success {
            addBehaviorErrorMessage = nil
            loadAll()
        } else {
            addBehaviorErrorMessage = "保存失败，请重试"
        }
        return success
    }

    func deleteBehavior(_ behavior: BehaviorItem) {
        let success = database.deleteBehavior(id: behavior.id)
        if success {
            loadAll()
        } else {
            addBehaviorErrorMessage = "删除失败，请重试"
        }
    }
}

@MainActor
private final class BehaviorYearViewModel: ObservableObject {
    @Published var monthSummaries: [MonthSummary] = []

    private let behavior: BehaviorItem
    private let database = BehaviorDatabase()

    init(behavior: BehaviorItem, year: Int) {
        self.behavior = behavior
        load(year: year)
    }

    var totalCount: Int {
        monthSummaries.reduce(0) { $0 + $1.count }
    }

    func load(year: Int) {
        monthSummaries = database.fetchMonthSummaries(for: behavior, year: year)
    }
}

@MainActor
private final class BehaviorMonthViewModel: ObservableObject {
    @Published var daySummaries: [DaySummary] = []

    private let behavior: BehaviorItem
    private let database = BehaviorDatabase()

    init(behavior: BehaviorItem, year: Int, month: Int) {
        self.behavior = behavior
        load(year: year, month: month)
    }

    var totalCount: Int {
        daySummaries.reduce(0) { $0 + $1.count }
    }

    func load(year: Int, month: Int) {
        daySummaries = database.fetchDaySummaries(for: behavior, year: year, month: month)
    }
}

@MainActor
private final class BehaviorDayViewModel: ObservableObject {
    @Published var hourSummaries: [HourSummary] = []

    private let behavior: BehaviorItem
    private let database = BehaviorDatabase()

    init(behavior: BehaviorItem, date: Date) {
        self.behavior = behavior
        load(date: date)
    }

    var totalCount: Int {
        hourSummaries.reduce(0) { $0 + $1.count }
    }

    func load(date: Date) {
        hourSummaries = database.fetchHourSummaries(for: behavior, date: date)
    }
}

// 主页面。
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var pendingBehavior: BehaviorItem?
    @State private var isPresentingAddBehavior = false
    @State private var behaviorPendingDeletion: BehaviorItem?

    private let dateText: String = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: Date())
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("今日行为记录")
                            .font(.largeTitle.bold())
                        Text(dateText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        ForEach(viewModel.behaviors) { behavior in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(behavior.name)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if !behavior.detail.isEmpty {
                                    Text(behavior.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.82))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                            .background(behavior.tintColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .onTapGesture {
                                pendingBehavior = behavior
                            }
                            .onLongPressGesture {
                                pendingBehavior = nil
                                isPresentingAddBehavior = false
                                if behaviorPendingDeletion == nil {
                                    behaviorPendingDeletion = behavior
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("今天统计")
                            .font(.headline)

                        ForEach(viewModel.todayCounts) { item in
                            NavigationLink {
                                BehaviorYearDetailView(behavior: item.behavior)
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(item.behavior.tintColor)
                                        .frame(width: 12, height: 12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.behavior.name)
                                            .foregroundStyle(.primary)

                                        if !item.behavior.detail.isEmpty {
                                            Text(item.behavior.detail)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text("\(item.count) 次")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("坏是做尽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresentingAddBehavior = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.loadAll()
            }
            .sheet(isPresented: $isPresentingAddBehavior) {
                AddBehaviorView(viewModel: viewModel)
            }
            .alert(
                "确认记录",
                isPresented: Binding(
                    get: { pendingBehavior != nil },
                    set: { isPresented in
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
                    viewModel.record(behavior)
                    pendingBehavior = nil
                }
            } message: { behavior in
                Text("确定要记录一次\(behavior.name)吗？")
            }
            .alert(
                "删除行为项",
                isPresented: Binding(
                    get: { behaviorPendingDeletion != nil },
                    set: { isPresented in
                        if !isPresented {
                            behaviorPendingDeletion = nil
                        }
                    }
                ),
                presenting: behaviorPendingDeletion
            ) { behavior in
                Button("取消", role: .cancel) {
                    behaviorPendingDeletion = nil
                }
                Button("删除", role: .destructive) {
                    viewModel.deleteBehavior(behavior)
                    behaviorPendingDeletion = nil
                }
            } message: { behavior in
                Text("确定要删除“\(behavior.name)”吗？这个行为项以及它的历史记录都会一起删除。")
            }
        }
    }
}

// 新增行为页。
private struct AddBehaviorView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ContentViewModel

    @State private var name = ""
    @State private var detail = ""
    @State private var selectedColor: BehaviorColorOption = .coral
    @State private var selectedPaletteHex: String?
    @State private var isShowingMoreColors = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var selectedPreviewColor: Color {
        if let selectedPaletteHex,
           let paletteItem = Array.extendedBehaviorPalette.first(where: { $0.hex == selectedPaletteHex }) {
            return paletteItem.color
        }
        return selectedColor.color
    }

    private var selectedColorHex: String {
        selectedPaletteHex ?? selectedColor.rawValue
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("行为名称", text: $name)
                    TextField("行为描述", text: $detail, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("按钮颜色") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BehaviorColorOption.allCases) { option in
                            Button {
                                selectedColor = option
                                selectedPaletteHex = nil
                            } label: {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if selectedPaletteHex == nil && selectedColor == option {
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: 2)
                                                    .padding(-4)
                                            }
                                        }

                                    Text(option.name)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        isShowingMoreColors = true
                    } label: {
                        HStack {
                            Image(systemName: "swatchpalette")
                            Text("更多颜色")
                            Spacer()
                            Circle()
                                .fill(selectedPreviewColor)
                                .frame(width: 20, height: 20)
                        }
                    }
                }

                Section("预览") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "行为名称" : name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "这里会显示行为描述" : detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(selectedPreviewColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .navigationTitle("新增行为")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let success = viewModel.addBehavior(
                            name: name,
                            detail: detail,
                            colorHex: selectedColorHex
                        )
                        if success {
                            dismiss()
                        }
                    }
                }
            }
            .alert(
                "保存失败",
                isPresented: Binding(
                    get: { viewModel.addBehaviorErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.addBehaviorErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("知道了", role: .cancel) {
                    viewModel.addBehaviorErrorMessage = nil
                }
            } message: {
                Text(viewModel.addBehaviorErrorMessage ?? "")
            }
            .sheet(isPresented: $isShowingMoreColors) {
                MoreColorsView(selectedHex: $selectedPaletteHex)
            }
        }
    }
}

// 更多颜色板。
private struct MoreColorsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHex: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array.extendedBehaviorPalette) { item in
                        Button {
                            selectedHex = item.hex
                            dismiss()
                        } label: {
                            VStack(spacing: 10) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedHex == item.hex {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 2)
                                                .padding(-5)
                                        }
                                    }

                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("更多颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BehaviorYearDetailView: View {
    let behavior: BehaviorItem

    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @StateObject private var viewModel: BehaviorYearViewModel

    init(behavior: BehaviorItem) {
        self.behavior = behavior
        let year = Calendar.current.component(.year, from: Date())
        _viewModel = StateObject(wrappedValue: BehaviorYearViewModel(behavior: behavior, year: year))
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        selectedYear -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("\(selectedYear)年")
                            .font(.system(size: 34, weight: .heavy))
                        Text("\(behavior.name) 共 \(viewModel.totalCount) 次")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        selectedYear += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                if !behavior.detail.isEmpty {
                    Text(behavior.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.monthSummaries) { summary in
                        NavigationLink {
                            BehaviorMonthDetailView(
                                behavior: behavior,
                                year: selectedYear,
                                month: summary.month
                            )
                        } label: {
                            MonthCardView(behavior: behavior, summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.001))
        .navigationTitle(behavior.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedYear) { _, newYear in
            viewModel.load(year: newYear)
        }
    }
}

private struct BehaviorMonthDetailView: View {
    let behavior: BehaviorItem
    let year: Int
    let month: Int

    @StateObject private var viewModel: BehaviorMonthViewModel

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdayTitles = ["日", "一", "二", "三", "四", "五", "六"]

    init(behavior: BehaviorItem, year: Int, month: Int) {
        self.behavior = behavior
        self.year = year
        self.month = month
        _viewModel = StateObject(
            wrappedValue: BehaviorMonthViewModel(behavior: behavior, year: year, month: month)
        )
    }

    private var monthDate: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }

    private var leadingEmptyDays: Int {
        calendar.component(.weekday, from: monthDate) - 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(month)月")
                        .font(.system(size: 30, weight: .heavy))
                    Text("\(behavior.name) 本月共 \(viewModel.totalCount) 次")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(weekdayTitles, id: \.self) { title in
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear.frame(height: 72)
                    }

                    ForEach(viewModel.daySummaries) { summary in
                        NavigationLink {
                            BehaviorDayDetailView(behavior: behavior, date: summary.date)
                        } label: {
                            DayCellView(
                                behavior: behavior,
                                summary: summary,
                                isToday: calendar.isDateInToday(summary.date)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(year)年\(month)月")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BehaviorDayDetailView: View {
    let behavior: BehaviorItem
    let date: Date

    @StateObject private var viewModel: BehaviorDayViewModel

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    init(behavior: BehaviorItem, date: Date) {
        self.behavior = behavior
        self.date = date
        _viewModel = StateObject(wrappedValue: BehaviorDayViewModel(behavior: behavior, date: date))
    }

    private var dayTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private var weekdayStripDates: [Date] {
        guard let startDate = calendar.date(byAdding: .day, value: -3, to: date) else {
            return [date]
        }

        return (0...6).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weekdayStripDates, id: \.self) { stripDate in
                            WeekStripItem(
                                date: stripDate,
                                isSelected: calendar.isDate(stripDate, inSameDayAs: date),
                                tintColor: behavior.tintColor
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dayTitle)
                        .font(.title2.bold())
                    Text("\(behavior.name) 当天共 \(viewModel.totalCount) 次")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.hourSummaries) { summary in
                        HourRowView(behavior: behavior, summary: summary)
                    }
                }
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("\(calendar.component(.day, from: date))日")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MonthCardView: View {
    let behavior: BehaviorItem
    let summary: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(summary.month)月")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(summary.count)")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(behavior.tintColor)

            Text("本月累计")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(behavior.tintColor.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct DayCellView: View {
    let behavior: BehaviorItem
    let summary: DaySummary
    let isToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(summary.day)")
                .font(.headline)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 30, height: 30)
                .background(isToday ? behavior.tintColor : Color.clear)
                .clipShape(Circle())

            Spacer(minLength: 0)

            Text(summary.count == 0 ? "-" : "\(summary.count)次")
                .font(.caption2.weight(.medium))
                .foregroundStyle(summary.count == 0 ? .secondary : behavior.tintColor)

            Capsule()
                .fill(summary.count == 0 ? Color.gray.opacity(0.12) : behavior.tintColor.opacity(0.8))
                .frame(height: 5)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct WeekStripItem: View {
    let date: Date
    let isSelected: Bool
    let tintColor: Color

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(calendar.component(.day, from: date))")
                .font(.headline)
            Text(weekdayText)
                .font(.caption)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(width: 48, height: 64)
        .background(isSelected ? tintColor : Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HourRowView: View {
    let behavior: BehaviorItem
    let summary: HourSummary

    var body: some View {
        HStack(spacing: 14) {
            Text(summary.hourText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)

            Rectangle()
                .fill(Color.gray.opacity(0.16))
                .frame(height: 1)

            if summary.count > 0 {
                Text("\(summary.count) 次")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(behavior.tintColor)
                    .clipShape(Capsule())
            } else {
                Text("无记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white.opacity(0.9))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.10))
                .frame(height: 1)
        }
    }
}

#Preview {
    ContentView()
}
