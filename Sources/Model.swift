import Foundation

struct Usage: Codable, Equatable {
    let usedGB: Double
    let remainingGB: Double
    let cycleStart: String
    let cycleEnd: String
    let capturedAt: String
    var totalGB: Double { usedGB + remainingGB }
    var fraction: Double { usedGB / totalGB }
    var remainingFraction: Double { remainingGB / totalGB }
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: capturedAt) ?? ISO8601DateFormatter().date(from: capturedAt)
    }
    static func day(_ value: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian); f.dateFormat = "yyyy-MM-dd"; f.isLenient = false
        guard let date = f.date(from: value), f.string(from: date) == value else { return nil }
        return date
    }
    func validate(now: Date = Date()) -> Bool {
        guard usedGB.isFinite, remainingGB.isFinite, usedGB >= 0, remainingGB >= 0,
              totalGB > 0, totalGB <= 1e9, let time = date,
              time <= now.addingTimeInterval(60), time > now.addingTimeInterval(-86400 * 60),
              let start = Self.day(cycleStart), let end = Self.day(cycleEnd) else { return false }
        return start < end
    }
    func daysUntilEnd(now: Date) -> Int? {
        guard let end = Self.day(cycleEnd) else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: end).day
    }
}
enum Phase: String { case idle, loading, ready, login, verification, offline, unreadable }
enum DisplayMode: String, CaseIterable, Identifiable {
    case remainingGB, remainingPercent, usedGB, usedPercent, icon
    var id: String { rawValue }
    var label: String {
        switch self { case .remainingGB: return "剩余流量"; case .remainingPercent: return "剩余百分比"; case .usedGB: return "已用流量"; case .usedPercent: return "已用百分比"; case .icon: return "仅用量图标" }
    }
    func title(usage: Usage?) -> String {
        guard let usage else { return self == .icon ? "" : "流量" }
        switch self {
        case .remainingGB: return String(format: "%.1fG", usage.remainingGB)
        case .remainingPercent: return String(format: "%.0f%%", usage.remainingFraction * 100)
        case .usedGB: return String(format: "已用 %.1fG", usage.usedGB)
        case .usedPercent: return String(format: "已用 %.0f%%", usage.fraction * 100)
        case .icon: return ""
        }
    }
}
struct Freshness {
    static func isStale(usage: Usage?, now: Date, interval: TimeInterval) -> Bool {
        guard let date = usage?.date else { return true }
        return now.timeIntervalSince(date) > max(interval * 2 + 60, 180)
    }
}
