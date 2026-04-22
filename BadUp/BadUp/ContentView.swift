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
    let userId: Int?
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

private extension BehaviorItem {
    init(serverBehaviorId: Int64, userId: Int?, behaviorName: String, behaviorDesc: String?, colorHex: String) {
        self.id = serverBehaviorId
        self.userId = userId
        self.name = behaviorName
        self.detail = behaviorDesc ?? ""
        self.colorHex = colorHex
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
            items.append(BehaviorItem(id: id, userId: nil, name: name, detail: detail, colorHex: colorHex))
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

    // 更新行为项。
    // 因为本地记录表当前用行为名称做关联，所以改名时要同步更新历史记录里的 behavior_type。
    func updateBehavior(id: Int64, name: String, detail: String, colorHex: String) -> Bool {
        guard let oldBehavior = fetchBehaviors().first(where: { $0.id == id }) else {
            return false
        }

        guard sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil) == SQLITE_OK else {
            return false
        }

        let updateBehaviorSQL = """
        UPDATE behaviors
        SET name = ?, detail = ?, color_hex = ?
        WHERE id = ?;
        """
        var updateBehaviorStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, updateBehaviorSQL, -1, &updateBehaviorStatement, nil) == SQLITE_OK else {
            sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
            return false
        }

        sqlite3_bind_text(updateBehaviorStatement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateBehaviorStatement, 2, (detail as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateBehaviorStatement, 3, (colorHex as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(updateBehaviorStatement, 4, id)
        let behaviorUpdated = sqlite3_step(updateBehaviorStatement) == SQLITE_DONE
        sqlite3_finalize(updateBehaviorStatement)

        guard behaviorUpdated else {
            sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
            return false
        }

        if oldBehavior.name != name {
            let updateRecordsSQL = "UPDATE behavior_records SET behavior_type = ? WHERE behavior_type = ?;"
            var updateRecordsStatement: OpaquePointer?
            guard sqlite3_prepare_v2(db, updateRecordsSQL, -1, &updateRecordsStatement, nil) == SQLITE_OK else {
                sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
                return false
            }

            sqlite3_bind_text(updateRecordsStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateRecordsStatement, 2, (oldBehavior.name as NSString).utf8String, -1, nil)
            let recordsUpdated = sqlite3_step(updateRecordsStatement) == SQLITE_DONE
            sqlite3_finalize(updateRecordsStatement)

            guard recordsUpdated else {
                sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
                return false
            }
        }

        return sqlite3_exec(db, "COMMIT;", nil, nil, nil) == SQLITE_OK
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

// 服务器行为接口封装。
// 页面层只和这个服务交互，不直接拼 PHP 接口参数。
private final class RemoteBehaviorService {
    static let shared = RemoteBehaviorService()

    private let session: URLSession
    private let decoder = JSONDecoder()

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

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    func fetchTodayCounts(userId: Int, date: Date = Date()) async throws -> [DailyBehaviorCount] {
        let response: ServerListResponse<ServerBehaviorToday> = try await post(
            "bad_BehaviorTodayCount.php",
            payload: [
                "userId": userId,
                "recordDate": dateFormatter.string(from: date)
            ]
        )

        return (response.list ?? []).map { item in
            DailyBehaviorCount(
                behavior: item.behaviorItem,
                count: item.todayCount.intValue
            )
        }
    }

    func addBehavior(userId: Int, name: String, detail: String, colorHex: String) async throws {
        let _: ServerDataResponse<ServerBehavior> = try await post(
            "bad_BehaviorInsert.php",
            payload: [
                "userId": userId,
                "behaviorName": name,
                "behaviorDesc": detail,
                "colorHex": colorHex
            ]
        )
    }

    func updateBehavior(userId: Int, behavior: BehaviorItem, name: String, detail: String, colorHex: String) async throws {
        let _: ServerDataResponse<ServerBehavior> = try await post(
            "bad_BehaviorUpdate.php",
            payload: [
                "userId": userId,
                "behaviorId": behavior.id,
                "behaviorName": name,
                "behaviorDesc": detail,
                "colorHex": colorHex
            ]
        )
    }

    func deleteBehavior(userId: Int, behavior: BehaviorItem) async throws {
        let _: EmptyServerResponse = try await post(
            "bad_BehaviorDelete.php",
            payload: [
                "userId": userId,
                "behaviorId": behavior.id
            ]
        )
    }

    func insertRecord(userId: Int, behavior: BehaviorItem, date: Date = Date()) async throws {
        let _: EmptyServerResponse = try await post(
            "bad_BehaviorRecordInsert.php",
            payload: [
                "userId": userId,
                "behaviorId": behavior.id,
                "recordDate": dateFormatter.string(from: date),
                "recordedAt": dateTimeFormatter.string(from: date),
                "countNum": 1,
                "clientUid": UUID().uuidString
            ]
        )
    }

    func fetchMonthSummaries(behavior: BehaviorItem, year: Int) async throws -> [MonthSummary] {
        let response: ServerListResponse<ServerMonthSummary> = try await post(
            "bad_BehaviorYearStats.php",
            payload: [
                "behaviorId": behavior.id,
                "year": year
            ]
        )
        var counts = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 0) })
        for item in response.list ?? [] {
            counts[item.monthNum.intValue] = item.totalCount.intValue
        }
        return (1...12).map { MonthSummary(month: $0, count: counts[$0, default: 0]) }
    }

    func fetchDaySummaries(behavior: BehaviorItem, year: Int, month: Int) async throws -> [DaySummary] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current

        guard
            let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let dayRange = calendar.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        let response: ServerListResponse<ServerDaySummary> = try await post(
            "bad_BehaviorMonthStats.php",
            payload: [
                "behaviorId": behavior.id,
                "year": year,
                "month": month
            ]
        )
        var counts = Dictionary(uniqueKeysWithValues: dayRange.map { ($0, 0) })
        for item in response.list ?? [] {
            counts[item.dayNum.intValue] = item.totalCount.intValue
        }

        return dayRange.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day)).map {
                DaySummary(date: $0, day: day, count: counts[day, default: 0])
            }
        }
    }

    func fetchHourSummaries(behavior: BehaviorItem, date: Date) async throws -> [HourSummary] {
        let response: ServerListResponse<ServerHourSummary> = try await post(
            "bad_BehaviorDayStats.php",
            payload: [
                "behaviorId": behavior.id,
                "recordDate": dateFormatter.string(from: date)
            ]
        )
        var counts = Dictionary(uniqueKeysWithValues: (0...23).map { ($0, 0) })
        for item in response.list ?? [] {
            counts[item.hourNum.intValue] = item.totalCount.intValue
        }
        return (0...23).map { HourSummary(hour: $0, count: counts[$0, default: 0]) }
    }

    private func post<T: Decodable>(_ endpoint: String, payload: [String: Any]) async throws -> T {
        let url = BadUpAPI.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse("不是 HTTP 响应")
        }
        let responseText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.invalidResponse("HTTP \(httpResponse.statusCode)，\(responseText)")
        }
        let decoded = try decoder.decode(T.self, from: data)

        if let apiResponse = decoded as? ServerResponseChecking, apiResponse.code != 200 {
            throw APIClientError.server(code: apiResponse.code, msg: apiResponse.msg)
        }

        return decoded
    }
}

private protocol ServerResponseChecking {
    var code: Int { get }
    var msg: String { get }
}

private struct ServerListResponse<T: Decodable>: Decodable, ServerResponseChecking {
    let code: Int
    let msg: String
    let list: [T]?
}

private struct ServerDataResponse<T: Decodable>: Decodable, ServerResponseChecking {
    let code: Int
    let msg: String
    let data: T?
}

private struct EmptyServerResponse: Decodable, ServerResponseChecking {
    let code: Int
    let msg: String
}

private struct LossyInt: Decodable {
    let intValue: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self.intValue = intValue
            return
        }
        if let stringValue = try? container.decode(String.self), let intValue = Int(stringValue) {
            self.intValue = intValue
            return
        }
        self.intValue = 0
    }
}

private struct ServerBehavior: Decodable {
    let behaviorId: LossyInt
    let userId: LossyInt?
    let behaviorName: String
    let behaviorDesc: String?
    let colorHex: String

    var behaviorItem: BehaviorItem {
        BehaviorItem(
            serverBehaviorId: Int64(behaviorId.intValue),
            userId: userId?.intValue,
            behaviorName: behaviorName,
            behaviorDesc: behaviorDesc,
            colorHex: colorHex
        )
    }
}

private struct ServerBehaviorToday: Decodable {
    let behaviorId: LossyInt
    let userId: LossyInt?
    let behaviorName: String
    let behaviorDesc: String?
    let colorHex: String
    let todayCount: LossyInt

    var behaviorItem: BehaviorItem {
        BehaviorItem(
            serverBehaviorId: Int64(behaviorId.intValue),
            userId: userId?.intValue,
            behaviorName: behaviorName,
            behaviorDesc: behaviorDesc,
            colorHex: colorHex
        )
    }
}

private struct ServerMonthSummary: Decodable {
    let monthNum: LossyInt
    let totalCount: LossyInt
}

private struct ServerDaySummary: Decodable {
    let dayNum: LossyInt
    let totalCount: LossyInt
}

private struct ServerHourSummary: Decodable {
    let hourNum: LossyInt
    let totalCount: LossyInt
}

@MainActor
// 首页视图模型：负责行为列表和今天统计。
private final class ContentViewModel: ObservableObject {
    @Published var behaviors: [BehaviorItem] = []
    @Published var todayCounts: [DailyBehaviorCount] = []
    @Published var addBehaviorErrorMessage: String?
    @Published var isLoading = false

    private let remoteService = RemoteBehaviorService.shared

    func loadAll(userId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let counts = try await remoteService.fetchTodayCounts(userId: userId)
            todayCounts = counts
            behaviors = counts.map(\.behavior)
            addBehaviorErrorMessage = nil
        } catch {
            addBehaviorErrorMessage = readableMessage(prefix: "加载失败", error: error)
        }
    }

    func record(_ behavior: BehaviorItem, userId: Int) async {
        do {
            try await remoteService.insertRecord(userId: userId, behavior: behavior)
            await loadAll(userId: userId)
        } catch {
            addBehaviorErrorMessage = readableMessage(prefix: "记录失败", error: error)
        }
    }

    func addBehavior(userId: Int, name: String, detail: String, colorHex: String) async -> Bool {
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

        do {
            try await remoteService.addBehavior(
                userId: userId,
                name: trimmedName,
                detail: trimmedDetail,
                colorHex: colorHex
            )
            addBehaviorErrorMessage = nil
            await loadAll(userId: userId)
            return true
        } catch {
            addBehaviorErrorMessage = readableMessage(prefix: "保存失败", error: error)
            return false
        }
    }

    func updateBehavior(_ behavior: BehaviorItem, userId: Int, name: String, detail: String, colorHex: String) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            addBehaviorErrorMessage = "行为名称不能为空"
            return false
        }

        if behaviors.contains(where: { $0.id != behavior.id && $0.name == trimmedName }) {
            addBehaviorErrorMessage = "已经存在同名行为，请换一个名称"
            return false
        }

        do {
            try await remoteService.updateBehavior(
                userId: userId,
                behavior: behavior,
                name: trimmedName,
                detail: trimmedDetail,
                colorHex: colorHex
            )
            addBehaviorErrorMessage = nil
            await loadAll(userId: userId)
            return true
        } catch {
            addBehaviorErrorMessage = readableMessage(prefix: "保存失败", error: error)
            return false
        }
    }

    func deleteBehavior(_ behavior: BehaviorItem, userId: Int) async {
        do {
            try await remoteService.deleteBehavior(userId: userId, behavior: behavior)
            await loadAll(userId: userId)
        } catch {
            addBehaviorErrorMessage = readableMessage(prefix: "删除失败", error: error)
        }
    }

    private func readableMessage(prefix: String, error: Error) -> String {
        if let apiError = error as? APIClientError {
            return "\(prefix)：\(apiError.localizedDescription)"
        }
        return "\(prefix)：\(error.localizedDescription)"
    }
}

@MainActor
private final class BehaviorYearViewModel: ObservableObject {
    @Published var monthSummaries: [MonthSummary] = []

    private let behavior: BehaviorItem
    private let remoteService = RemoteBehaviorService.shared

    init(behavior: BehaviorItem) {
        self.behavior = behavior
    }

    var totalCount: Int {
        monthSummaries.reduce(0) { $0 + $1.count }
    }

    func load(year: Int) async {
        do {
            monthSummaries = try await remoteService.fetchMonthSummaries(behavior: behavior, year: year)
        } catch {
            monthSummaries = (1...12).map { MonthSummary(month: $0, count: 0) }
        }
    }
}

@MainActor
private final class BehaviorMonthViewModel: ObservableObject {
    @Published var daySummaries: [DaySummary] = []

    private let behavior: BehaviorItem
    private let remoteService = RemoteBehaviorService.shared

    init(behavior: BehaviorItem) {
        self.behavior = behavior
    }

    var totalCount: Int {
        daySummaries.reduce(0) { $0 + $1.count }
    }

    func load(year: Int, month: Int) async {
        do {
            daySummaries = try await remoteService.fetchDaySummaries(behavior: behavior, year: year, month: month)
        } catch {
            daySummaries = []
        }
    }
}

@MainActor
private final class BehaviorDayViewModel: ObservableObject {
    @Published var hourSummaries: [HourSummary] = []

    private let behavior: BehaviorItem
    private let remoteService = RemoteBehaviorService.shared

    init(behavior: BehaviorItem) {
        self.behavior = behavior
    }

    var totalCount: Int {
        hourSummaries.reduce(0) { $0 + $1.count }
    }

    func load(date: Date) async {
        do {
            hourSummaries = try await remoteService.fetchHourSummaries(behavior: behavior, date: date)
        } catch {
            hourSummaries = (0...23).map { HourSummary(hour: $0, count: 0) }
        }
    }
}

// 主页面。
struct ContentView: View {
    @EnvironmentObject private var session: SessionStore

    @StateObject private var viewModel = ContentViewModel()
    @State private var pendingBehavior: BehaviorItem?
    @State private var isPresentingAddBehavior = false
    @State private var behaviorPendingDeletion: BehaviorItem?
    @State private var behaviorPendingEditing: BehaviorItem?

    private var currentUserId: Int? {
        session.user?.userId
    }

    private let dateText: String = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: Date())
    }()

    var body: some View {
        NavigationStack {
            HomeContentView(
                dateText: dateText,
                behaviors: viewModel.behaviors,
                todayCounts: viewModel.todayCounts,
                onBehaviorTap: beginRecord,
                onBehaviorLongPress: beginBehaviorAction
            )
            .navigationTitle("坏是做尽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task(id: currentUserId) {
                if let currentUserId {
                    await viewModel.loadAll(userId: currentUserId)
                }
            }
            .modifier(homePresentationModifier)
        }
        // 强制根视图撑满屏幕，并把背景铺到安全区外，避免出现“圆角白卡+黑边”的观感。
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.001))
        .ignoresSafeArea()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isPresentingAddBehavior = true
            } label: {
                Image(systemName: "plus")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                MoreView(user: session.user)
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
            }
        }
    }

    private var homePresentationModifier: HomePresentationModifier {
        HomePresentationModifier(
            viewModel: viewModel,
            userId: currentUserId,
            isPresentingAddBehavior: $isPresentingAddBehavior,
            behaviorPendingEditing: $behaviorPendingEditing,
            pendingBehavior: $pendingBehavior,
            behaviorPendingDeletion: $behaviorPendingDeletion
        )
    }

    private func beginRecord(_ behavior: BehaviorItem) {
        pendingBehavior = behavior
    }

    private func beginBehaviorAction(_ behavior: BehaviorItem) {
        pendingBehavior = nil
        isPresentingAddBehavior = false
        if behaviorPendingDeletion == nil {
            behaviorPendingDeletion = behavior
        }
    }
}

// 首页主体滚动内容。
private struct HomeContentView: View {
    let dateText: String
    let behaviors: [BehaviorItem]
    let todayCounts: [DailyBehaviorCount]
    let onBehaviorTap: (BehaviorItem) -> Void
    let onBehaviorLongPress: (BehaviorItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HomeHeaderView(dateText: dateText)
                behaviorButtonList
                todayCountList
            }
            // 关键：让 ScrollView 内容强制占满宽度，避免在真机上被居中成“卡片”。
            .frame(maxWidth: .infinity, alignment: .top)
        }
        // 让内容更接近全屏：用 ScrollView 的内容边距替代整块 padding，
        // 同时给背景铺满整个屏幕（包含安全区外的区域）。
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .contentMargins(.vertical, 12, for: .scrollContent)
    }

    private var behaviorButtonList: some View {
        VStack(spacing: 12) {
            ForEach(behaviors) { behavior in
                BehaviorButtonRow(behavior: behavior) {
                    onBehaviorTap(behavior)
                } onLongPress: {
                    onBehaviorLongPress(behavior)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayCountList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今天统计")
                .font(.headline)

            ForEach(todayCounts) { item in
                NavigationLink {
                    BehaviorYearDetailView(behavior: item.behavior)
                } label: {
                    TodayCountRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 首页弹窗和 sheet 集中放在这里，避免 ContentView.body 过大导致编译器类型推断超时。
private struct HomePresentationModifier: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    let userId: Int?

    @Binding var isPresentingAddBehavior: Bool
    @Binding var behaviorPendingEditing: BehaviorItem?
    @Binding var pendingBehavior: BehaviorItem?
    @Binding var behaviorPendingDeletion: BehaviorItem?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresentingAddBehavior) {
                AddBehaviorView(viewModel: viewModel, userId: userId)
            }
            .sheet(item: $behaviorPendingEditing) { behavior in
                AddBehaviorView(viewModel: viewModel, userId: userId, editingBehavior: behavior)
            }
            .overlay {
                if let behavior = pendingBehavior {
                    BadUpDialog(
                        tintColor: behavior.tintColor,
                        title: "确认记录",
                        messagePrefix: "确定要记录一次",
                        highlightedText: behavior.name,
                        messageSuffix: "吗？",
                        primaryTitle: "确认记录",
                        secondaryTitle: "取消",
                        primaryRole: nil,
                        primaryAction: {
                            confirmRecord(behavior)
                        },
                        secondaryAction: {
                            pendingBehavior = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else if let behavior = behaviorPendingDeletion {
                    BadUpDialog(
                        tintColor: behavior.tintColor,
                        title: "管理行为项",
                        messagePrefix: "你要编辑还是删除",
                        highlightedText: behavior.name,
                        messageSuffix: "？删除会连历史记录一起删除。",
                        primaryTitle: "进入编辑",
                        secondaryTitle: "删除",
                        primaryRole: nil,
                        secondaryRole: .destructive,
                        primaryAction: {
                            behaviorPendingEditing = behavior
                            behaviorPendingDeletion = nil
                        },
                        secondaryAction: {
                            confirmDelete(behavior)
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: pendingBehavior)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: behaviorPendingDeletion)
    }

    private func confirmRecord(_ behavior: BehaviorItem) {
        if let userId {
            Task {
                await viewModel.record(behavior, userId: userId)
            }
        }
        pendingBehavior = nil
    }

    private func confirmDelete(_ behavior: BehaviorItem) {
        if let userId {
            Task {
                await viewModel.deleteBehavior(behavior, userId: userId)
            }
        }
        behaviorPendingDeletion = nil
    }
}

// App 内自定义确认弹窗。
// 比系统 Alert 更柔和，也可以使用行为颜色做视觉关联。
private struct BadUpDialog: View {
    let tintColor: Color
    let title: String
    let messagePrefix: String
    let highlightedText: String
    let messageSuffix: String
    let primaryTitle: String
    let secondaryTitle: String
    let primaryRole: ButtonRole?
    let secondaryRole: ButtonRole?
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    init(
        tintColor: Color,
        title: String,
        messagePrefix: String,
        highlightedText: String,
        messageSuffix: String,
        primaryTitle: String,
        secondaryTitle: String,
        primaryRole: ButtonRole? = nil,
        secondaryRole: ButtonRole? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) {
        self.tintColor = tintColor
        self.title = title
        self.messagePrefix = messagePrefix
        self.highlightedText = highlightedText
        self.messageSuffix = messageSuffix
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.primaryRole = primaryRole
        self.secondaryRole = secondaryRole
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.26)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Capsule()
                    .fill(tintColor.opacity(0.88))
                    .frame(width: 46, height: 5)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.primary)

                    highlightedMessage
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                HStack(spacing: 12) {
                    Button(role: secondaryRole, action: secondaryAction) {
                        Text(secondaryTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(secondaryRole == .destructive ? Color.red : Color.secondary)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(role: primaryRole, action: primaryAction) {
                        Text(primaryTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(tintColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.14), radius: 28, x: 0, y: 16)
            )
            .padding(.horizontal, 26)
        }
    }

    private var highlightedMessage: Text {
        Text(messagePrefix + "“")
            .foregroundStyle(.secondary)
        + Text(highlightedText)
            .foregroundStyle(tintColor)
            .fontWeight(.heavy)
        + Text("”" + messageSuffix)
            .foregroundStyle(.secondary)
    }
}

// 首页标题区。
private struct HomeHeaderView: View {
    let dateText: String

    var body: some View {
        VStack(spacing: 8) {
            Text("今日行为记录")
                .font(.largeTitle.bold())
            Text(dateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 首页行为按钮。
private struct BehaviorButtonRow: View {
    let behavior: BehaviorItem
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
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
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
    }
}

// 首页“今天统计”的单行。
private struct TodayCountRow: View {
    let item: DailyBehaviorCount

    var body: some View {
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

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(item.count)")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(item.behavior.tintColor)

                Text("次")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.behavior.tintColor.opacity(0.82))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// 详情页顶部的总次数文字。
// 数字用行为颜色强调，其它说明文字保持弱化，阅读层级更清楚。
private struct TotalCountText: View {
    let prefix: String
    let count: Int
    let tintColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(prefix)
                .foregroundStyle(.secondary)

            Text("\(count)")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tintColor)

            Text("次")
                .foregroundStyle(tintColor.opacity(0.82))
        }
        .font(.subheadline)
    }
}

// 更多页面。
// 这里先展示登录用户信息，后续可以继续追加设置项。
private struct MoreView: View {
    let user: BadUpUser?

    var body: some View {
        List {
            Section("用户信息") {
                InfoRow(title: "UserId", value: user.map { String($0.userId) } ?? "-")
                InfoRow(title: "UserCode", value: user?.userCode ?? "-")
                InfoRow(title: "DeviceId", value: user?.deviceId ?? "-")
                InfoRow(title: "Platform", value: user?.platform ?? "-")
                InfoRow(title: "AppVersion", value: user?.appVersion ?? "-")
                InfoRow(title: "SystemVersion", value: user?.systemVersion ?? "-")
            }

            Section("更多") {
                Text("其他选项后面再加")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("更多")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// 新增行为页。
private struct AddBehaviorView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ContentViewModel
    let userId: Int?
    let editingBehavior: BehaviorItem?

    @State private var name = ""
    @State private var detail = ""
    @State private var selectedColor: BehaviorColorOption = .coral
    @State private var selectedPaletteHex: String?
    @State private var isShowingMoreColors = false
    @State private var isSaving = false

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

    init(viewModel: ContentViewModel, userId: Int?, editingBehavior: BehaviorItem? = nil) {
        self.viewModel = viewModel
        self.userId = userId
        self.editingBehavior = editingBehavior

        _name = State(initialValue: editingBehavior?.name ?? "")
        _detail = State(initialValue: editingBehavior?.detail ?? "")

        if let editingBehavior {
            if let defaultColor = BehaviorColorOption(rawValue: editingBehavior.colorHex) {
                _selectedColor = State(initialValue: defaultColor)
                _selectedPaletteHex = State(initialValue: nil)
            } else {
                _selectedColor = State(initialValue: .coral)
                _selectedPaletteHex = State(initialValue: editingBehavior.colorHex)
            }
        } else {
            _selectedColor = State(initialValue: .coral)
            _selectedPaletteHex = State(initialValue: nil)
        }
    }

    private func hasNoChanges(comparedWith behavior: BehaviorItem) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalDetail = behavior.detail.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedName == behavior.name
            && trimmedDetail == originalDetail
            && selectedColorHex == behavior.colorHex
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
            .navigationTitle(editingBehavior == nil ? "新增行为" : "编辑行为")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        guard let userId else {
                            viewModel.addBehaviorErrorMessage = "用户信息异常，请重新打开 App"
                            return
                        }

                        if let editingBehavior, hasNoChanges(comparedWith: editingBehavior) {
                            dismiss()
                            return
                        }

                        isSaving = true
                        Task {
                            let success: Bool
                            if let editingBehavior {
                                success = await viewModel.updateBehavior(
                                    editingBehavior,
                                    userId: userId,
                                    name: name,
                                    detail: detail,
                                    colorHex: selectedColorHex
                                )
                            } else {
                                success = await viewModel.addBehavior(
                                    userId: userId,
                                    name: name,
                                    detail: detail,
                                    colorHex: selectedColorHex
                                )
                            }

                            isSaving = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(isSaving)
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
        _viewModel = StateObject(wrappedValue: BehaviorYearViewModel(behavior: behavior))
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
                        TotalCountText(
                            prefix: "\(behavior.name) 共",
                            count: viewModel.totalCount,
                            tintColor: behavior.tintColor
                        )
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
        .task(id: selectedYear) {
            await viewModel.load(year: selectedYear)
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
            wrappedValue: BehaviorMonthViewModel(behavior: behavior)
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
                    TotalCountText(
                        prefix: "\(behavior.name) 本月共",
                        count: viewModel.totalCount,
                        tintColor: behavior.tintColor
                    )
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
        .task {
            await viewModel.load(year: year, month: month)
        }
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
        _viewModel = StateObject(wrappedValue: BehaviorDayViewModel(behavior: behavior))
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
                    TotalCountText(
                        prefix: "\(behavior.name) 当天共",
                        count: viewModel.totalCount,
                        tintColor: behavior.tintColor
                    )
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
        .task {
            await viewModel.load(date: date)
        }
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
