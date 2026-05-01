//
//  ContentView.swift
//  BadUp
//
//  Created by chenrs on 2026/4/16.
//

import SwiftUI
import Combine
import UIKit

// 更丰富的颜色板项。
// 这些颜色会在“更多颜色”弹层中展示。
private struct ColorPaletteItem: Identifiable, Hashable {
    let hex: String
    let name: String
    let color: Color

    var id: String { hex }
}

// 可选的习惯颜色。
// 这里用预设颜色而不是自由取色，能让按钮和统计页风格保持整齐。
private enum BehaviorColorOption: String, CaseIterable, Identifiable {
    case coral = "#F55F52"
    case orange = "#F9B536"
    case cyan = "#31B3C5"
    case blue = "#6C7EF7"
    case green = "#43C77A"
    case pink = "#F56EA4"
    case purple = "#8C5CF6"

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
        case .purple:
            return Color(red: 0.55, green: 0.36, blue: 0.96)
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
        case .purple: return "紫罗兰"
        }
    }

    static func from(hex: String) -> BehaviorColorOption {
        BehaviorColorOption(rawValue: hex) ?? .coral
    }
}

// 习惯类型。
// 好习惯记录一次 +1 分，坏习惯记录一次 -10 分；分值由服务端在写入记录时固化。
private enum BehaviorKind: Int, CaseIterable, Identifiable, Hashable {
    case good = 1
    case bad = -1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .good: return "好习惯"
        case .bad: return "坏习惯"
        }
    }

    var subtitle: String {
        switch self {
        case .good: return "记录一次 +1 分"
        case .bad: return "记录一次 -10 分"
        }
    }

    var tintColor: Color {
        switch self {
        case .good: return Color(red: 0.26, green: 0.78, blue: 0.48)
        case .bad: return Color(red: 0.96, green: 0.37, blue: 0.32)
        }
    }

    static func fromServerValue(_ value: Int?) -> BehaviorKind {
        value == 1 ? .good : .bad
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

// 习惯项模型。
// 默认习惯和用户新增习惯都统一走这个结构。
private struct BehaviorItem: Identifiable, Hashable {
    let id: Int64
    let userId: Int?
    let name: String
    let detail: String
    let colorHex: String
    var behaviorKind: BehaviorKind = .bad
    var sortOrder: Int = 0

    var tintColor: Color {
        if let paletteItem = Array.extendedBehaviorPalette.first(where: { $0.hex == colorHex }) {
            return paletteItem.color
        }
        return BehaviorColorOption.from(hex: colorHex).color
    }
}

private extension BehaviorItem {
    init(
        serverBehaviorId: Int64,
        userId: Int?,
        behaviorName: String,
        behaviorDesc: String?,
        colorHex: String,
        behaviorType: Int?,
        sortOrder: Int?
    ) {
        self.id = serverBehaviorId
        self.userId = userId
        self.name = behaviorName
        self.detail = behaviorDesc ?? ""
        self.colorHex = colorHex
        self.behaviorKind = BehaviorKind.fromServerValue(behaviorType)
        self.sortOrder = sortOrder ?? 0
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

// 服务器习惯接口封装。
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

    func addBehavior(userId: Int, name: String, detail: String, colorHex: String, behaviorKind: BehaviorKind) async throws {
        let _: ServerDataResponse<ServerBehavior> = try await post(
            "bad_BehaviorInsert.php",
            payload: [
                "userId": userId,
                "behaviorName": name,
                "behaviorDesc": detail,
                "colorHex": colorHex,
                "behaviorType": behaviorKind.rawValue
            ]
        )
    }

    func updateBehavior(userId: Int, behavior: BehaviorItem, name: String, detail: String, colorHex: String) async throws {
        let _: ServerDataResponse<ServerBehavior> = try await post(
            "bad_BehaviorUpdate.php",
            payload: [
                "userId": userId,
                "behaviorId": Int(behavior.id),
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
                "behaviorId": Int(behavior.id)
            ]
        )
    }

    func updateBehaviorSort(userId: Int, behaviors: [BehaviorItem]) async throws {
        let behaviorIds = behaviors.map { Int($0.id) }
        let _: ServerDataResponse<ServerSortUpdate> = try await post(
            "bad_BehaviorSortUpdate.php",
            payload: [
                "userId": userId,
                "behaviorIds": behaviorIds
            ]
        )
    }

    func insertRecord(userId: Int, behavior: BehaviorItem, date: Date = Date()) async throws {
        let _: EmptyServerResponse = try await post(
            "bad_BehaviorRecordInsert.php",
            payload: [
                "userId": userId,
                "behaviorId": Int(behavior.id),
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
                "behaviorId": Int(behavior.id),
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
                "behaviorId": Int(behavior.id),
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
                "behaviorId": Int(behavior.id),
                "recordDate": dateFormatter.string(from: date)
            ]
        )
        var counts = Dictionary(uniqueKeysWithValues: (0...23).map { ($0, 0) })
        for item in response.list ?? [] {
            counts[item.hourNum.intValue] = item.totalCount.intValue
        }
        return (0...23).map { HourSummary(hour: $0, count: counts[$0, default: 0]) }
    }

    func fetchUserBehaviorScore(userId: Int) async throws -> UserBehaviorScore {
        let response: ServerDataResponse<UserBehaviorScore> = try await post(
            "bad_UserBehaviorScore.php",
            payload: [
                "userId": userId
            ]
        )
        return response.data ?? UserBehaviorScore(behaviorScore: 0, totalCount: 0)
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
    let behaviorType: LossyInt?
    let sortOrder: LossyInt?

    var behaviorItem: BehaviorItem {
        BehaviorItem(
            serverBehaviorId: Int64(behaviorId.intValue),
            userId: userId?.intValue,
            behaviorName: behaviorName,
            behaviorDesc: behaviorDesc,
            colorHex: colorHex,
            behaviorType: behaviorType?.intValue,
            sortOrder: sortOrder?.intValue
        )
    }
}

private struct ServerBehaviorToday: Decodable {
    let behaviorId: LossyInt
    let userId: LossyInt?
    let behaviorName: String
    let behaviorDesc: String?
    let colorHex: String
    let behaviorType: LossyInt?
    let sortOrder: LossyInt?
    let todayCount: LossyInt

    var behaviorItem: BehaviorItem {
        BehaviorItem(
            serverBehaviorId: Int64(behaviorId.intValue),
            userId: userId?.intValue,
            behaviorName: behaviorName,
            behaviorDesc: behaviorDesc,
            colorHex: colorHex,
            behaviorType: behaviorType?.intValue,
            sortOrder: sortOrder?.intValue
        )
    }
}

private struct ServerSortUpdate: Decodable {
    let updated: LossyInt?
}

private struct UserBehaviorScore: Decodable {
    let behaviorScore: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case behaviorScore
        case totalCount
    }

    init(behaviorScore: Int, totalCount: Int) {
        self.behaviorScore = behaviorScore
        self.totalCount = totalCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeInt(_ key: CodingKeys) -> Int {
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue
            }
            if let stringValue = try? container.decode(String.self, forKey: key) {
                return Int(stringValue) ?? 0
            }
            return 0
        }

        self.behaviorScore = decodeInt(.behaviorScore)
        self.totalCount = decodeInt(.totalCount)
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
// 首页视图模型：负责习惯列表和今天统计。
private final class ContentViewModel: ObservableObject {
    @Published var behaviors: [BehaviorItem] = []
    @Published var todayCounts: [DailyBehaviorCount] = []
    @Published var addBehaviorErrorMessage: String?
    @Published var isLoading = false
    @Published var didLoadInitialData = false

    private let remoteService = RemoteBehaviorService.shared

    func loadAll(userId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let counts = try await remoteService.fetchTodayCounts(userId: userId)
            todayCounts = counts
            behaviors = counts.map(\.behavior)
            didLoadInitialData = true
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

    func addBehavior(userId: Int, name: String, detail: String, colorHex: String, behaviorKind: BehaviorKind) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            addBehaviorErrorMessage = "习惯名称不能为空"
            return false
        }

        if behaviors.contains(where: { $0.name == trimmedName }) {
            addBehaviorErrorMessage = "这个习惯名称已经存在，请换一个名称"
            return false
        }

        do {
            try await remoteService.addBehavior(
                userId: userId,
                name: trimmedName,
                detail: trimmedDetail,
                colorHex: colorHex,
                behaviorKind: behaviorKind
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
            addBehaviorErrorMessage = "习惯名称不能为空"
            return false
        }

        if behaviors.contains(where: { $0.id != behavior.id && $0.name == trimmedName }) {
            addBehaviorErrorMessage = "这个习惯名称已经存在，请换一个名称"
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

    func moveBehavior(from sourceIndex: Int, to destinationIndex: Int, userId: Int) async {
        guard behaviors.indices.contains(sourceIndex), behaviors.indices.contains(destinationIndex), sourceIndex != destinationIndex else {
            return
        }

        let originalBehaviors = behaviors
        let originalCounts = todayCounts

        var movedBehaviors = behaviors
        let item = movedBehaviors.remove(at: sourceIndex)
        movedBehaviors.insert(item, at: destinationIndex)

        let countById = Dictionary(uniqueKeysWithValues: todayCounts.map { ($0.behavior.id, $0.count) })
        behaviors = movedBehaviors
        todayCounts = movedBehaviors.map { behavior in
            DailyBehaviorCount(behavior: behavior, count: countById[behavior.id, default: 0])
        }

        do {
            try await remoteService.updateBehaviorSort(userId: userId, behaviors: movedBehaviors)
            addBehaviorErrorMessage = nil
        } catch {
            behaviors = originalBehaviors
            todayCounts = originalCounts
            addBehaviorErrorMessage = readableMessage(prefix: "排序保存失败", error: error)
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
            let description = apiError.localizedDescription
            if description.contains("Integrity constraint")
                || description.contains("Duplicate")
                || description.contains("DuplicateBehaviorName")
                || description.contains("这个习惯名称已经存在") {
                return "\(prefix)：这个习惯名称已经存在，请换一个名称"
            }
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
    @State private var behaviorPendingDeleteConfirmation: BehaviorItem?
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
            homeBody
            .navigationTitle("芽记")
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

    @ViewBuilder
    private var homeBody: some View {
        if viewModel.didLoadInitialData {
            HomeContentView(
                dateText: dateText,
                behaviors: viewModel.behaviors,
                todayCounts: viewModel.todayCounts,
                onBehaviorTap: beginRecord,
                onBehaviorLongPress: beginBehaviorAction,
                onBehaviorMove: moveBehavior
            )
        } else {
            HomeLoadingView(
                errorMessage: viewModel.addBehaviorErrorMessage,
                retryAction: retryLoadHome
            )
        }
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
            behaviorPendingDeletion: $behaviorPendingDeletion,
            behaviorPendingDeleteConfirmation: $behaviorPendingDeleteConfirmation
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

    private func moveBehavior(from sourceIndex: Int, to destinationIndex: Int) {
        guard let currentUserId else {
            return
        }

        Task {
            await viewModel.moveBehavior(from: sourceIndex, to: destinationIndex, userId: currentUserId)
        }
    }

    private func retryLoadHome() {
        guard let currentUserId else {
            return
        }

        Task {
            await viewModel.loadAll(userId: currentUserId)
        }
    }
}

// 首页首屏数据加载完成前的占位页。
// 避免登录成功后先渲染空首页，再突然出现习惯列表。
private struct HomeLoadingView: View {
    let errorMessage: String?
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            if let errorMessage {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.23, green: 0.56, blue: 0.36))

                Text("加载首页失败")
                    .font(.headline)

                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                Button("重试") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.23, green: 0.56, blue: 0.36))
            } else {
                ProgressView()
                    .tint(Color(red: 0.23, green: 0.56, blue: 0.36))

                Text("正在加载习惯…")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.99, blue: 0.97))
    }
}

// 首页主体滚动内容。
private struct HomeContentView: View {
    let dateText: String
    let behaviors: [BehaviorItem]
    let todayCounts: [DailyBehaviorCount]
    let onBehaviorTap: (BehaviorItem) -> Void
    let onBehaviorLongPress: (BehaviorItem) -> Void
    let onBehaviorMove: (Int, Int) -> Void

    private let estimatedRowHeight: CGFloat = 86
    private let minimumSortDragDistance: CGFloat = 28

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
            ForEach(Array(behaviors.enumerated()), id: \.element.id) { index, behavior in
                BehaviorButtonRow(behavior: behavior) {
                    onBehaviorTap(behavior)
                } onLongPress: {
                    onBehaviorLongPress(behavior)
                } onLongDragEnd: { translationHeight in
                    moveBehavior(index: index, translationHeight: translationHeight)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moveBehavior(index: Int, translationHeight: CGFloat) {
        guard abs(translationHeight) >= minimumSortDragDistance else {
            if behaviors.indices.contains(index) {
                onBehaviorLongPress(behaviors[index])
            }
            return
        }

        let stepCount = max(1, Int((abs(translationHeight) / estimatedRowHeight).rounded(.up)))
        let step = translationHeight > 0 ? stepCount : -stepCount
        let targetIndex = min(max(index + step, 0), behaviors.count - 1)
        if targetIndex != index {
            onBehaviorMove(index, targetIndex)
        } else if behaviors.indices.contains(index) {
            onBehaviorLongPress(behaviors[index])
        }
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
    @Binding var behaviorPendingDeleteConfirmation: BehaviorItem?

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
                        title: "管理习惯项",
                        messagePrefix: "编辑或删除",
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
                            behaviorPendingDeleteConfirmation = behavior
                            behaviorPendingDeletion = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else if let behavior = behaviorPendingDeleteConfirmation {
                    BadUpDialog(
                        tintColor: behavior.tintColor,
                        title: "确认删除",
                        messagePrefix: "确定删除",
                        highlightedText: behavior.name,
                        messageSuffix: "？历史记录也会一起删除。",
                        primaryTitle: "确认删除",
                        secondaryTitle: "取消",
                        primaryRole: .destructive,
                        primaryAction: {
                            confirmDelete(behavior)
                        },
                        secondaryAction: {
                            behaviorPendingDeleteConfirmation = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: pendingBehavior)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: behaviorPendingDeletion)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: behaviorPendingDeleteConfirmation)
            .alert(
                "提示",
                isPresented: Binding(
                    get: {
                        viewModel.didLoadInitialData
                            && viewModel.addBehaviorErrorMessage != nil
                            && !isPresentingAddBehavior
                            && behaviorPendingEditing == nil
                    },
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
        behaviorPendingDeleteConfirmation = nil
    }
}

// App 内自定义确认弹窗。
// 比系统 Alert 更柔和，也可以使用习惯颜色做视觉关联。
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
            Text("今日习惯记录")
                .font(.largeTitle.bold())
            Text(dateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 首页习惯按钮。
private struct BehaviorButtonRow: View {
    let behavior: BehaviorItem
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onLongDragEnd: (CGFloat) -> Void

    @State private var isLongPressActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(behavior.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !behavior.detail.isEmpty {
                Text(behavior.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(behavior.tintColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .scaleEffect(isLongPressActive ? 1.035 : 1)
        .shadow(
            color: isLongPressActive ? behavior.tintColor.opacity(0.36) : .clear,
            radius: isLongPressActive ? 16 : 0,
            x: 0,
            y: isLongPressActive ? 10 : 0
        )
        .zIndex(isLongPressActive ? 10 : 0)
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isLongPressActive)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            LongPressDragGestureBridge(
                minimumPressDuration: 0.38,
                dragThreshold: 28,
                onTap: onTap,
                onLongPress: onLongPress,
                onLongDragEnd: onLongDragEnd,
                onPressStateChange: { isActive in
                    isLongPressActive = isActive
                }
            )
        }
    }
}

// 用 UIKit 手势桥接避免 SwiftUI 高优先级手势抢走 ScrollView 的正常滑动。
private struct LongPressDragGestureBridge: UIViewRepresentable {
    let minimumPressDuration: TimeInterval
    let dragThreshold: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onLongDragEnd: (CGFloat) -> Void
    let onPressStateChange: (Bool) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        view.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = minimumPressDuration
        longPressGesture.allowableMovement = 22
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.delegate = context.coordinator
        view.addGestureRecognizer(longPressGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.dragThreshold = dragThreshold
        context.coordinator.onTap = onTap
        context.coordinator.onLongPress = onLongPress
        context.coordinator.onLongDragEnd = onLongDragEnd
        context.coordinator.onPressStateChange = onPressStateChange
        if let longPressGesture = uiView.gestureRecognizers?.compactMap({ $0 as? UILongPressGestureRecognizer }).first {
            longPressGesture.minimumPressDuration = minimumPressDuration
            longPressGesture.allowableMovement = 22
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.onPressStateChange(false)
        coordinator.setContainingScrollViewEnabled(from: uiView, isEnabled: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            dragThreshold: dragThreshold,
            onTap: onTap,
            onLongPress: onLongPress,
            onLongDragEnd: onLongDragEnd,
            onPressStateChange: onPressStateChange
        )
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var dragThreshold: CGFloat
        var onTap: () -> Void
        var onLongPress: () -> Void
        var onLongDragEnd: (CGFloat) -> Void
        var onPressStateChange: (Bool) -> Void

        private var startPoint: CGPoint = .zero
        private var latestTranslation: CGSize = .zero

        init(
            dragThreshold: CGFloat,
            onTap: @escaping () -> Void,
            onLongPress: @escaping () -> Void,
            onLongDragEnd: @escaping (CGFloat) -> Void,
            onPressStateChange: @escaping (Bool) -> Void
        ) {
            self.dragThreshold = dragThreshold
            self.onTap = onTap
            self.onLongPress = onLongPress
            self.onLongDragEnd = onLongDragEnd
            self.onPressStateChange = onPressStateChange
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else {
                return
            }
            onTap()
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            let point = gesture.location(in: gesture.view)

            switch gesture.state {
            case .began:
                startPoint = point
                latestTranslation = .zero
                onPressStateChange(true)
                setContainingScrollViewEnabled(from: gesture.view, isEnabled: false)
            case .changed:
                latestTranslation = CGSize(
                    width: point.x - startPoint.x,
                    height: point.y - startPoint.y
                )
            case .ended:
                latestTranslation = CGSize(
                    width: point.x - startPoint.x,
                    height: point.y - startPoint.y
                )
                if abs(latestTranslation.height) >= dragThreshold {
                    onLongDragEnd(latestTranslation.height)
                } else {
                    onLongPress()
                }
                latestTranslation = .zero
                onPressStateChange(false)
                setContainingScrollViewEnabled(from: gesture.view, isEnabled: true)
            case .cancelled, .failed:
                latestTranslation = .zero
                onPressStateChange(false)
                setContainingScrollViewEnabled(from: gesture.view, isEnabled: true)
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func setContainingScrollViewEnabled(from view: UIView?, isEnabled: Bool) {
            var currentView = view?.superview
            while let candidate = currentView {
                if let scrollView = candidate as? UIScrollView {
                    scrollView.isScrollEnabled = isEnabled
                    return
                }
                currentView = candidate.superview
            }
        }
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
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !item.behavior.detail.isEmpty {
                    Text(item.behavior.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
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
// 数字用习惯颜色强调，其它说明文字保持弱化，阅读层级更清楚。
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
// 展示当前登录用户的种子信息和 App 基本信息。
private struct MoreView: View {
    let user: BadUpUser?

    @State private var behaviorScore: Int?
    @State private var scoreLoadError: String?
    @State private var isShowingCopyConfirmation = false

    private let contactText = "BooTry"

    var body: some View {
        List {
            Section("种子信息") {
                InfoRow(title: "种子编号", value: user.map { String($0.userId) } ?? "-")
                NavigationLink {
                    GrowthIndexView(index: behaviorScore ?? 0)
                } label: {
                    InfoRow(
                        title: "生长指数",
                        value: scoreText,
                        valueColor: scoreColor
                    )
                }
                InfoRow(title: "播种日期", value: formattedCreatedAt)
                InfoRow(title: "发芽土地", value: platformDisplayName)
            }

            Section("关于芽记") {
                InfoRow(title: "当前版本", value: currentAppVersion)
                Button {
                    copyContactText()
                } label: {
                    CopyableInfoRow(title: "联系我们", value: contactText)
                }
                .buttonStyle(.plain)
                InfoRow(title: "ICP备案信息", value: "粤ICP备19137866号-3")
            }
        }
        .navigationTitle("关于芽记")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已复制", isPresented: $isShowingCopyConfirmation) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("已复制 \(contactText)")
        }
        .task(id: user?.userId) {
            await loadBehaviorScore()
        }
    }

    private var scoreText: String {
        if let behaviorScore {
            return String(behaviorScore)
        }
        if scoreLoadError != nil {
            return "加载失败"
        }
        return "加载中"
    }

    private var scoreColor: Color? {
        guard let behaviorScore else {
            return nil
        }
        if behaviorScore > 0 {
            return Color(red: 0.26, green: 0.78, blue: 0.48)
        }
        if behaviorScore < 0 {
            return Color(red: 0.96, green: 0.37, blue: 0.32)
        }
        return .secondary
    }

    private var formattedCreatedAt: String {
        guard let createdAt = user?.createdAt, !createdAt.isEmpty else {
            return "-"
        }
        if createdAt.count >= 10 {
            return String(createdAt.prefix(10))
        }
        return createdAt
    }

    private var platformDisplayName: String {
        guard let platform = user?.platform?.lowercased(), !platform.isEmpty else {
            return "-"
        }
        if platform.contains("wechat") || platform.contains("weixin") || platform.contains("mini") || platform.contains("wx") {
            return "微信小程序"
        }
        if platform.contains("android") {
            return "Android"
        }
        if platform.contains("ios") {
            return "iOS App"
        }
        return user?.platform ?? "-"
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private func copyContactText() {
        UIPasteboard.general.string = contactText
        isShowingCopyConfirmation = true
    }

    private func loadBehaviorScore() async {
        guard let userId = user?.userId else {
            behaviorScore = 0
            return
        }
        do {
            let score = try await RemoteBehaviorService.shared.fetchUserBehaviorScore(userId: userId)
            behaviorScore = score.behaviorScore
            scoreLoadError = nil
        } catch {
            behaviorScore = nil
            scoreLoadError = error.localizedDescription
        }
    }
}

private struct CopyableInfoRow: View {
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

            Image(systemName: "doc.on.doc")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor ?? Color.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct GrowthIndexView: View {
    let index: Int

    private let stages: [GrowthStage] = [
        GrowthStage(name: "静谧萌发", desc: "生命在泥土中沉睡，积蓄破土的力量。"),
        GrowthStage(name: "破土嫩芽", desc: "勇敢地顶开泥土，向世界问好。"),
        GrowthStage(name: "写实双叶", desc: "舒展的嫩芽，汲取岁月精华。"),
        GrowthStage(name: "韧性初显", desc: "躯干逐渐挺拔，无惧微风掠过。"),
        GrowthStage(name: "向光生长", desc: "每一个分叉，都是向天空的探索。"),
        GrowthStage(name: "少年青葱", desc: "枝干交叠错落，初现生命繁华。"),
        GrowthStage(name: "繁枝错落", desc: "岁月留下痕迹，构筑独特风骨。"),
        GrowthStage(name: "绿意叠嶂", desc: "叶影在阳光下，交织光阴故事。"),
        GrowthStage(name: "生命礼赞", desc: "厚重而苍劲，守护脚下土地。"),
        GrowthStage(name: "参天屹立", desc: "阅尽千帆，归于大自然的平静。")
    ]

    private var stageIndex: Int {
        if index <= 0 { return 0 }
        if index <= 10 { return 1 }
        if index <= 50 { return 2 }
        if index <= 100 { return 3 }
        if index <= 300 { return 4 }
        if index <= 500 { return 5 }
        if index <= 1000 { return 6 }
        if index <= 2000 { return 7 }
        if index <= 3000 { return 8 }
        return 9
    }

    private var stage: GrowthStage {
        stages[stageIndex]
    }

    private var progress: Double {
        min(max(Double(index), 0), 5000) / 5000
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("种子芽记")
                    .font(.title.weight(.light))
                    .kerning(6)
                    .foregroundStyle(Color(red: 0.24, green: 0.16, blue: 0.13))

                Text(stage.desc)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.43, green: 0.56, blue: 0.43))
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)

            GrowthPlantIllustration(stageIndex: stageIndex)
                .frame(maxWidth: 300, maxHeight: 300)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(stage.name)
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.18, green: 0.49, blue: 0.20))

                    Spacer()

                    Text("生长指数：\(index)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress)
                    .tint(Color(red: 0.18, green: 0.49, blue: 0.20))
            }
            .padding(20)
            .background(Color.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 10)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 0.96),
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("生长指数")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GrowthStage {
    let name: String
    let desc: String
}

private struct GrowthPlantIllustration: View {
    let stageIndex: Int

    var body: some View {
        Canvas { context, size in
            drawBackground(in: size, context: &context)
            drawSoil(in: size, context: &context)

            if stageIndex <= 0 {
                drawSeed(in: size, context: &context)
            } else if stageIndex == 1 {
                drawSprout(in: size, context: &context)
            } else {
                drawTree(in: size, context: &context)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var clampedStage: Int {
        min(max(stageIndex, 0), 9)
    }

    private func drawBackground(in size: CGSize, context: inout GraphicsContext) {
        let side = min(size.width, size.height)
        let rect = CGRect(
            x: (size.width - side) / 2 + side * 0.04,
            y: (size.height - side) / 2 + side * 0.04,
            width: side * 0.92,
            height: side * 0.92
        )
        let glowRect = rect.insetBy(dx: -side * 0.03, dy: -side * 0.03)

        context.fill(
            Path(ellipseIn: glowRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.92, green: 0.98, blue: 0.90),
                    Color(red: 0.98, green: 1.00, blue: 0.96)
                ]),
                startPoint: CGPoint(x: glowRect.minX, y: glowRect.minY),
                endPoint: CGPoint(x: glowRect.maxX, y: glowRect.maxY)
            )
        )

        context.stroke(
            Path(ellipseIn: rect),
            with: .color(Color.white.opacity(0.85)),
            lineWidth: 1.2
        )
    }

    private func drawSoil(in size: CGSize, context: inout GraphicsContext) {
        let side = min(size.width, size.height)
        let soilRect = CGRect(
            x: size.width * 0.23,
            y: size.height * 0.75,
            width: size.width * 0.54,
            height: side * 0.08
        )
        let shadowRect = soilRect.offsetBy(dx: 0, dy: side * 0.025).insetBy(dx: -side * 0.02, dy: 0)

        context.fill(
            Path(ellipseIn: shadowRect),
            with: .color(Color(red: 0.36, green: 0.52, blue: 0.30).opacity(0.16))
        )
        context.fill(
            Path(ellipseIn: soilRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.36, green: 0.25, blue: 0.14),
                    Color(red: 0.65, green: 0.45, blue: 0.24),
                    Color(red: 0.28, green: 0.20, blue: 0.12)
                ]),
                startPoint: CGPoint(x: soilRect.minX, y: soilRect.minY),
                endPoint: CGPoint(x: soilRect.maxX, y: soilRect.maxY)
            )
        )
    }

    private func drawSeed(in size: CGSize, context: inout GraphicsContext) {
        let side = min(size.width, size.height)
        drawLeaf(
            center: CGPoint(x: size.width * 0.50, y: size.height * 0.72),
            size: CGSize(width: side * 0.20, height: side * 0.12),
            angle: -18,
            baseColor: Color(red: 0.50, green: 0.31, blue: 0.16),
            highlightColor: Color(red: 0.82, green: 0.57, blue: 0.30),
            context: &context
        )
    }

    private func drawSprout(in size: CGSize, context: inout GraphicsContext) {
        let side = min(size.width, size.height)
        let base = CGPoint(x: size.width * 0.50, y: size.height * 0.76)
        let top = CGPoint(x: size.width * 0.50, y: size.height * 0.56)

        var stem = Path()
        stem.move(to: base)
        stem.addCurve(
            to: top,
            control1: CGPoint(x: size.width * 0.55, y: size.height * 0.68),
            control2: CGPoint(x: size.width * 0.46, y: size.height * 0.61)
        )
        context.stroke(
            stem,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.33, green: 0.54, blue: 0.20),
                    Color(red: 0.53, green: 0.78, blue: 0.31)
                ]),
                startPoint: base,
                endPoint: top
            ),
            style: StrokeStyle(lineWidth: side * 0.025, lineCap: .round)
        )

        drawLeaf(
            center: CGPoint(x: size.width * 0.45, y: size.height * 0.55),
            size: CGSize(width: side * 0.20, height: side * 0.11),
            angle: -30,
            baseColor: Color(red: 0.25, green: 0.64, blue: 0.25),
            highlightColor: Color(red: 0.70, green: 0.91, blue: 0.45),
            context: &context
        )
        drawLeaf(
            center: CGPoint(x: size.width * 0.56, y: size.height * 0.54),
            size: CGSize(width: side * 0.22, height: side * 0.12),
            angle: 28,
            baseColor: Color(red: 0.29, green: 0.70, blue: 0.30),
            highlightColor: Color(red: 0.74, green: 0.94, blue: 0.48),
            context: &context
        )
    }

    private func drawTree(in size: CGSize, context: inout GraphicsContext) {
        let side = min(size.width, size.height)
        let stage = CGFloat(clampedStage)
        let base = CGPoint(x: size.width * 0.50, y: size.height * 0.77)
        let top = CGPoint(x: size.width * (0.49 + stage * 0.002), y: size.height * (0.55 - stage * 0.028))
        let baseWidth = side * (0.030 + stage * 0.005)
        let topWidth = side * (0.012 + stage * 0.002)

        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - baseWidth, y: base.y))
        trunk.addCurve(
            to: CGPoint(x: top.x - topWidth, y: top.y),
            control1: CGPoint(x: size.width * 0.40, y: size.height * 0.68),
            control2: CGPoint(x: size.width * 0.55, y: size.height * 0.59)
        )
        trunk.addLine(to: CGPoint(x: top.x + topWidth, y: top.y))
        trunk.addCurve(
            to: CGPoint(x: base.x + baseWidth, y: base.y),
            control1: CGPoint(x: size.width * 0.60, y: size.height * 0.58),
            control2: CGPoint(x: size.width * 0.55, y: size.height * 0.69)
        )
        trunk.closeSubpath()
        context.fill(
            trunk,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.24, green: 0.15, blue: 0.08),
                    Color(red: 0.55, green: 0.34, blue: 0.17),
                    Color(red: 0.33, green: 0.20, blue: 0.11)
                ]),
                startPoint: CGPoint(x: base.x - baseWidth, y: base.y),
                endPoint: CGPoint(x: base.x + baseWidth, y: top.y)
            )
        )

        drawBarkHighlight(from: base, to: top, in: size, context: &context)

        let branches = branchSpecs(for: clampedStage, base: base, top: top, size: size)
        for branch in branches {
            drawBranch(branch, side: side, context: &context)
        }

        for branch in branches {
            drawLeafCluster(at: branch.end, branchIndex: branch.seed, side: side, context: &context)
        }

        drawLeafCluster(at: CGPoint(x: top.x, y: top.y - side * 0.035), branchIndex: 99, side: side, context: &context)
    }

    private func drawBarkHighlight(from base: CGPoint, to top: CGPoint, in size: CGSize, context: inout GraphicsContext) {
        var highlight = Path()
        highlight.move(to: CGPoint(x: base.x - size.width * 0.006, y: base.y - size.height * 0.02))
        highlight.addCurve(
            to: CGPoint(x: top.x - size.width * 0.004, y: top.y + size.height * 0.03),
            control1: CGPoint(x: size.width * 0.46, y: size.height * 0.68),
            control2: CGPoint(x: size.width * 0.52, y: size.height * 0.58)
        )
        context.stroke(
            highlight,
            with: .color(Color(red: 0.82, green: 0.58, blue: 0.32).opacity(0.34)),
            style: StrokeStyle(lineWidth: min(size.width, size.height) * 0.006, lineCap: .round)
        )
    }

    private struct BranchSpec {
        let start: CGPoint
        let control: CGPoint
        let end: CGPoint
        let width: CGFloat
        let seed: Int
    }

    private func branchSpecs(for stage: Int, base: CGPoint, top: CGPoint, size: CGSize) -> [BranchSpec] {
        let side = min(size.width, size.height)
        let rawSpecs: [BranchSpec] = [
            BranchSpec(
                start: CGPoint(x: base.x - side * 0.005, y: base.y - side * 0.18),
                control: CGPoint(x: size.width * 0.33, y: size.height * 0.58),
                end: CGPoint(x: size.width * 0.29, y: size.height * 0.50),
                width: side * 0.018,
                seed: 1
            ),
            BranchSpec(
                start: CGPoint(x: base.x + side * 0.006, y: base.y - side * 0.25),
                control: CGPoint(x: size.width * 0.68, y: size.height * 0.52),
                end: CGPoint(x: size.width * 0.72, y: size.height * 0.44),
                width: side * 0.017,
                seed: 2
            ),
            BranchSpec(
                start: CGPoint(x: top.x - side * 0.004, y: top.y + side * 0.08),
                control: CGPoint(x: size.width * 0.38, y: size.height * 0.40),
                end: CGPoint(x: size.width * 0.35, y: size.height * 0.33),
                width: side * 0.014,
                seed: 3
            ),
            BranchSpec(
                start: CGPoint(x: top.x + side * 0.004, y: top.y + side * 0.04),
                control: CGPoint(x: size.width * 0.63, y: size.height * 0.37),
                end: CGPoint(x: size.width * 0.64, y: size.height * 0.29),
                width: side * 0.013,
                seed: 4
            ),
            BranchSpec(
                start: CGPoint(x: top.x, y: top.y + side * 0.02),
                control: CGPoint(x: size.width * 0.50, y: size.height * 0.28),
                end: CGPoint(x: size.width * 0.48, y: size.height * 0.21),
                width: side * 0.012,
                seed: 5
            )
        ]

        let count = min(rawSpecs.count, max(2, stage - 1))
        return Array(rawSpecs.prefix(count))
    }

    private func drawBranch(_ branch: BranchSpec, side: CGFloat, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: branch.start)
        path.addQuadCurve(to: branch.end, control: branch.control)
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.27, green: 0.17, blue: 0.09),
                    Color(red: 0.54, green: 0.34, blue: 0.17)
                ]),
                startPoint: branch.start,
                endPoint: branch.end
            ),
            style: StrokeStyle(lineWidth: branch.width, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawLeafCluster(at center: CGPoint, branchIndex: Int, side: CGFloat, context: inout GraphicsContext) {
        let leafTotal = min(8, max(3, clampedStage))
        for index in 0..<leafTotal {
            let angle = Double((index * 47 + branchIndex * 19) % 130) - 65
            let radius = side * CGFloat(0.018 + 0.012 * Double(index % 3))
            let offsetX = cos(CGFloat(angle) * .pi / 180) * radius
            let offsetY = sin(CGFloat(angle) * .pi / 180) * radius * 0.65
            let leafCenter = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
            let leafSize = CGSize(
                width: side * CGFloat(0.105 + 0.012 * Double((index + branchIndex) % 3)),
                height: side * CGFloat(0.052 + 0.006 * Double(index % 2))
            )
            let palette = leafPalette(index + branchIndex)
            drawLeaf(
                center: leafCenter,
                size: leafSize,
                angle: angle,
                baseColor: palette.base,
                highlightColor: palette.highlight,
                context: &context
            )
        }
    }

    private func leafPalette(_ index: Int) -> (base: Color, highlight: Color) {
        let palettes = [
            (Color(red: 0.18, green: 0.52, blue: 0.22), Color(red: 0.76, green: 0.92, blue: 0.45)),
            (Color(red: 0.26, green: 0.66, blue: 0.28), Color(red: 0.83, green: 0.96, blue: 0.54)),
            (Color(red: 0.13, green: 0.43, blue: 0.24), Color(red: 0.66, green: 0.86, blue: 0.42))
        ]
        return palettes[index % palettes.count]
    }

    private func drawLeaf(
        center: CGPoint,
        size: CGSize,
        angle: Double,
        baseColor: Color,
        highlightColor: Color,
        context: inout GraphicsContext
    ) {
        var leafContext = context
        leafContext.translateBy(x: center.x, y: center.y)
        leafContext.rotate(by: .degrees(angle))

        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        let leafPath = Path(ellipseIn: rect)
        leafContext.fill(
            leafPath,
            with: .linearGradient(
                Gradient(colors: [highlightColor, baseColor]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )
        leafContext.stroke(
            leafPath,
            with: .color(Color.white.opacity(0.18)),
            lineWidth: 0.7
        )

        var vein = Path()
        vein.move(to: CGPoint(x: rect.minX + size.width * 0.16, y: 0))
        vein.addLine(to: CGPoint(x: rect.maxX - size.width * 0.16, y: 0))
        leafContext.stroke(
            vein,
            with: .color(Color.white.opacity(0.22)),
            style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
        )
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.35)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.35)
        )
        return path
    }
}

private struct BehaviorKindPickerView: View {
    @Binding var selectedKind: BehaviorKind
    let isEditable: Bool

    var body: some View {
        HStack(spacing: 10) {
            ForEach(BehaviorKind.allCases) { kind in
                BehaviorKindOptionButton(
                    kind: kind,
                    isSelected: kind == selectedKind,
                    isEditable: isEditable
                ) {
                    selectedKind = kind
                }
            }
        }
    }
}

private struct BehaviorKindOptionButton: View {
    let kind: BehaviorKind
    let isSelected: Bool
    let isEditable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(kind.title)
                    .font(.headline)
                Text(kind.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? kind.tintColor : Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? kind.tintColor.opacity(0.12) : Color.gray.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? kind.tintColor : Color.clear, lineWidth: 1.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEditable)
    }
}

private struct AddBehaviorFormSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 2)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// 新增/编辑习惯页。
private struct AddBehaviorView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ContentViewModel
    let userId: Int?
    let editingBehavior: BehaviorItem?

    @State private var name = ""
    @State private var detail = ""
    @State private var selectedBehaviorKind: BehaviorKind = .good
    @State private var selectedColor: BehaviorColorOption = .coral
    @State private var selectedPaletteHex: String?
    @State private var isShowingMoreColors = false
    @State private var isSaving = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

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
        _selectedBehaviorKind = State(initialValue: editingBehavior?.behaviorKind ?? .good)

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
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    basicInfoSection
                    behaviorKindSection
                    colorSection
                    previewSection
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingBehavior == nil ? "新增习惯" : "编辑习惯")
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
                                    colorHex: selectedColorHex,
                                    behaviorKind: selectedBehaviorKind
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

    private var basicInfoSection: some View {
        AddBehaviorFormSection("基本信息") {
            VStack(spacing: 0) {
                TextField("习惯名称", text: $name)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)

                Divider()
                    .padding(.leading, 14)

                TextField("习惯描述", text: $detail, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 86, alignment: .topLeading)
            }
        }
    }

    private var behaviorKindSection: some View {
        AddBehaviorFormSection(editingBehavior == nil ? "习惯类型" : "习惯类型（编辑时不可修改）") {
            BehaviorKindPickerView(
                selectedKind: $selectedBehaviorKind,
                isEditable: editingBehavior == nil
            )
            .padding(12)
        }
    }

    private var colorSection: some View {
        AddBehaviorFormSection("按钮颜色") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BehaviorColorOption.allCases) { option in
                    colorOptionButton(option)
                }
                moreColorGridButton
            }
            .padding(12)
        }
    }

    private var previewSection: some View {
        AddBehaviorFormSection("预览") {
            VStack(alignment: .leading, spacing: 6) {
                Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "习惯名称" : name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "这里会显示习惯描述" : detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(selectedPreviewColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(12)
        }
    }

    private func colorOptionButton(_ option: BehaviorColorOption) -> some View {
        Button {
            selectedColor = option
            selectedPaletteHex = nil
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(option.color)
                    .frame(width: 30, height: 30)
                    .overlay {
                        if selectedPaletteHex == nil && selectedColor == option {
                            Circle()
                                .stroke(Color.primary, lineWidth: 2)
                                .padding(-4)
                        }
                    }

                Text(option.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var moreColorGridButton: some View {
        Button {
            isShowingMoreColors = true
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.37, blue: 0.32))
                        .frame(width: 12, height: 12)
                        .offset(x: -8, y: -8)
                    Circle()
                        .fill(Color(red: 0.98, green: 0.71, blue: 0.21))
                        .frame(width: 12, height: 12)
                        .offset(x: 8, y: -8)
                    Circle()
                        .fill(Color(red: 0.19, green: 0.70, blue: 0.77))
                        .frame(width: 12, height: 12)
                        .offset(x: -8, y: 8)
                    Circle()
                        .fill(Color(red: 0.26, green: 0.78, blue: 0.48))
                        .frame(width: 12, height: 12)
                        .offset(x: 8, y: 8)
                }
                .frame(width: 30, height: 30)

                Text("更多")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
                LazyVGrid(columns: columns, spacing: 12) {
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
                        Color.clear.frame(height: 58)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("\(summary.month)月")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(summary.count)")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(behavior.tintColor)

            Text("本月累计")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(12)
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
        VStack(alignment: .leading, spacing: 5) {
            Text("\(summary.day)")
                .font(.headline)
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .frame(width: 28, height: 28)
                .background(isToday ? behavior.tintColor : Color.clear)
                .clipShape(Circle())

            Spacer(minLength: 0)

            Text(summary.count == 0 ? "-" : "\(summary.count)次")
                .font(.caption2.weight(.medium))
                .foregroundStyle(summary.count == 0 ? Color.secondary : behavior.tintColor)

            Capsule()
                .fill(summary.count == 0 ? Color.gray.opacity(0.12) : behavior.tintColor.opacity(0.8))
                .frame(height: 4)
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
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
        .foregroundStyle(isSelected ? Color.white : Color.primary)
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
