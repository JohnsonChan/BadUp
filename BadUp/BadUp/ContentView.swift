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

    // 给不同坏习惯一组固定配色，详情页里可以保持识别度。
    var tintColor: Color {
        switch self {
        case .masturbation:
            return Color(red: 0.96, green: 0.38, blue: 0.32)
        case .shortVideo:
            return Color(red: 0.98, green: 0.71, blue: 0.20)
        case .stayingUpLate:
            return Color(red: 0.15, green: 0.67, blue: 0.76)
        case .overeating:
            return Color(red: 0.42, green: 0.58, blue: 0.94)
        }
    }
}

// 表示“某一天里某种行为的统计结果”。
// 这个结构体主要给首页展示使用。
private struct DailyBehaviorCount: Identifiable {
    let behavior: BehaviorType
    var count: Int

    var id: String { behavior.id }
}

// 表示某一年里每个月的累计次数。
private struct MonthSummary: Identifiable {
    let month: Int
    var count: Int

    var id: Int { month }
}

// 表示某个月里每天的累计次数。
private struct DaySummary: Identifiable {
    let date: Date
    let day: Int
    var count: Int

    var id: Date { date }
}

// 表示某一天里每小时的累计次数。
private struct HourSummary: Identifiable {
    let hour: Int
    var count: Int

    var id: Int { hour }

    var hourText: String {
        String(format: "%02d:00", hour)
    }
}

// 负责和 SQLite 数据库打交道。
// 这里把建表、迁移、插入、查询都封装起来，界面层只需要调用方法即可。
private final class BehaviorDatabase {
    // SQLite 原生数据库连接指针。
    private var db: OpaquePointer?

    // 当前工程里统一使用公历和本地时区来处理日期。
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    // 统一把日期格式化成 yyyy-MM-dd，确保“按天”存储时规则一致。
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // 额外存一份精确到秒的时间戳，方便做日视图里的小时统计。
    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // 老数据没有 `recorded_at` 字段，所以查询时要给它一个兜底时间。
    private let recordedAtExpression = "COALESCE(recorded_at, record_date || ' 12:00:00')"

    // 初始化时先打开数据库，再确保表已经创建好并迁移到最新结构。
    init() {
        openDatabase()
        createTableIfNeeded()
        addRecordedAtColumnIfNeeded()
    }

    // 对象释放时关闭数据库连接，避免资源泄漏。
    deinit {
        sqlite3_close(db)
    }

    // 插入一条新的行为记录。
    // 每点一次确认，就写入一条 count = 1 的记录，同时记录精确时间。
    func insertRecord(for behavior: BehaviorType, on date: Date = Date()) {
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
        sqlite3_bind_text(statement, 3, (behavior.rawValue as NSString).utf8String, -1, nil)

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
        var counts = Dictionary(uniqueKeysWithValues: BehaviorType.allCases.map { ($0, 0) })

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetch prepare failed")
            return BehaviorType.allCases.map { DailyBehaviorCount(behavior: $0, count: 0) }
        }

        defer { sqlite3_finalize(statement) }

        let dateString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, 1, (dateString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let behaviorTypeCString = sqlite3_column_text(statement, 0),
                let behavior = BehaviorType(rawValue: String(cString: behaviorTypeCString))
            else {
                continue
            }

            counts[behavior] = Int(sqlite3_column_int(statement, 1))
        }

        return BehaviorType.allCases.map {
            DailyBehaviorCount(behavior: $0, count: counts[$0, default: 0])
        }
    }

    // 查询某个行为在某一年里 12 个月的累计次数。
    func fetchMonthSummaries(for behavior: BehaviorType, year: Int) -> [MonthSummary] {
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

        sqlite3_bind_text(statement, 1, (behavior.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(year))

        while sqlite3_step(statement) == SQLITE_ROW {
            let month = Int(sqlite3_column_int(statement, 0))
            let count = Int(sqlite3_column_int(statement, 1))
            counts[month] = count
        }

        return (1...12).map { MonthSummary(month: $0, count: counts[$0, default: 0]) }
    }

    // 查询某个行为在某个月里每天的累计次数。
    func fetchDaySummaries(for behavior: BehaviorType, year: Int, month: Int) -> [DaySummary] {
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
        sqlite3_bind_text(statement, 1, (behavior.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (yearString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (monthString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            let day = Int(sqlite3_column_int(statement, 0))
            let count = Int(sqlite3_column_int(statement, 1))
            counts[day] = count
        }

        return dayRange.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day)).map {
                DaySummary(date: $0, day: day, count: counts[day, default: 0])
            }
        }
    }

    // 查询某个行为在某一天里 24 小时的累计次数。
    func fetchHourSummaries(for behavior: BehaviorType, date: Date) -> [HourSummary] {
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
        sqlite3_bind_text(statement, 1, (behavior.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (dayString as NSString).utf8String, -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            let hour = Int(sqlite3_column_int(statement, 0))
            let count = Int(sqlite3_column_int(statement, 1))
            counts[hour] = count
        }

        return (0...23).map { HourSummary(hour: $0, count: counts[$0, default: 0]) }
    }

    // 打开位于 Documents 目录中的 SQLite 文件。
    private func openDatabase() {
        let fileURL = Self.databaseURL()
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("open database failed")
        }
    }

    // 如果表不存在就创建一张记录表。
    // 新表同时保存日期和精确时间戳。
    private func createTableIfNeeded() {
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
            print("create table failed")
        }
    }

    // 给老库补一列 `recorded_at`，避免已经装在手机上的数据丢失。
    private func addRecordedAtColumnIfNeeded() {
        let sql = "ALTER TABLE behavior_records ADD COLUMN recorded_at TEXT;"
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // 数据库文件的保存路径。
    private static func databaseURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("behavior_records.sqlite")
    }
}

@MainActor
// 首页视图模型：负责连接首页和数据库。
// 界面按钮触发它，数据变化后通过 `@Published` 自动刷新 SwiftUI。
private final class ContentViewModel: ObservableObject {
    @Published var todayCounts: [DailyBehaviorCount] = BehaviorType.allCases.map {
        DailyBehaviorCount(behavior: $0, count: 0)
    }

    private let database = BehaviorDatabase()

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

@MainActor
// 年视图模型：负责读取某一行为在一年内每个月的累计次数。
private final class BehaviorYearViewModel: ObservableObject {
    @Published var monthSummaries: [MonthSummary] = []

    private let behavior: BehaviorType
    private let database = BehaviorDatabase()

    init(behavior: BehaviorType, year: Int) {
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
// 月视图模型：负责读取某一行为在某个月里每天的累计次数。
private final class BehaviorMonthViewModel: ObservableObject {
    @Published var daySummaries: [DaySummary] = []

    private let behavior: BehaviorType
    private let database = BehaviorDatabase()

    init(behavior: BehaviorType, year: Int, month: Int) {
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
// 日视图模型：负责读取某一行为在某一天里每小时的累计次数。
private final class BehaviorDayViewModel: ObservableObject {
    @Published var hourSummaries: [HourSummary] = []

    private let behavior: BehaviorType
    private let database = BehaviorDatabase()

    init(behavior: BehaviorType, date: Date) {
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
    @State private var pendingBehavior: BehaviorType?

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
                        // 遍历所有行为，自动生成首页操作按钮。
                        ForEach(BehaviorType.allCases) { behavior in
                            Button {
                                pendingBehavior = behavior
                            } label: {
                                Text(behavior.buttonTitle)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(behavior.tintColor.gradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("今天统计")
                            .font(.headline)

                        // 首页统计项现在可以点进详情页。
                        ForEach(viewModel.todayCounts) { item in
                            NavigationLink {
                                BehaviorYearDetailView(behavior: item.behavior)
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(item.behavior.tintColor)
                                        .frame(width: 12, height: 12)

                                    Text(item.behavior.rawValue)
                                        .foregroundStyle(.primary)

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
            .onAppear {
                // 页面出现时再刷新一次，避免从后台回来时数据过旧。
                viewModel.loadTodayCounts()
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
                Text("确定要记录一次\(behavior.rawValue)吗？")
            }
        }
    }
}

// 年视图：展示某个行为在一整年 12 个月里的分布。
private struct BehaviorYearDetailView: View {
    let behavior: BehaviorType

    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @StateObject private var viewModel: BehaviorYearViewModel

    init(behavior: BehaviorType) {
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
                        Text("\(behavior.rawValue) 共 \(viewModel.totalCount) 次")
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
        .navigationTitle(behavior.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedYear) { _, newYear in
            viewModel.load(year: newYear)
        }
    }
}

// 月视图：像日历一样展示一个月里每天的次数。
private struct BehaviorMonthDetailView: View {
    let behavior: BehaviorType
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

    init(behavior: BehaviorType, year: Int, month: Int) {
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
        let weekday = calendar.component(.weekday, from: monthDate)
        return weekday - 1
    }

    private var titleText: String {
        "\(month)月"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(titleText)
                        .font(.system(size: 30, weight: .heavy))
                    Text("\(behavior.rawValue) 本月共 \(viewModel.totalCount) 次")
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
                        Color.clear
                            .frame(height: 72)
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

// 日视图：展示一天 24 小时的分布。
private struct BehaviorDayDetailView: View {
    let behavior: BehaviorType
    let date: Date

    @StateObject private var viewModel: BehaviorDayViewModel

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()

    init(behavior: BehaviorType, date: Date) {
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
                    Text("\(behavior.rawValue) 当天共 \(viewModel.totalCount) 次")
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

// 年视图里的月份卡片。
private struct MonthCardView: View {
    let behavior: BehaviorType
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

// 月视图里的每天单元格。
private struct DayCellView: View {
    let behavior: BehaviorType
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

// 日视图顶部的一周日期条。
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

// 日视图里的小时行。
private struct HourRowView: View {
    let behavior: BehaviorType
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

// Xcode 预览。
#Preview {
    ContentView()
}
