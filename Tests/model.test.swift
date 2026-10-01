import Foundation
@main struct ModelTests {
    static func main() {
        var count = 0
        func check(_ name: String, _ predicate: @autoclosure () -> Bool) { precondition(predicate(), name); count += 1; print("PASS \(name)") }
        let now = Date()
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        func sample(_ used: Double = 125, _ left: Double = 375, _ start: String = "2026-10-01", _ end: String = "2026-11-01", _ captured: Date? = nil) -> Usage {
            Usage(usedGB: used, remainingGB: left, cycleStart: start, cycleEnd: end, capturedAt: formatter.string(from: captured ?? now))
        }
        let usage = sample()
        check("演示页面额度为 500 GB", usage.totalGB == 500)
        check("有效数据被接受", usage.validate(now: now))
        check("剩余比例计算正确", abs(usage.remainingFraction - 0.75) < 0.0000001)
        check("未使用时合法", sample(0, 500).validate(now: now))
        check("耗尽时合法", sample(500, 0).validate(now: now))
        check("负数拒绝", !sample(-1, 500).validate(now: now))
        check("NaN 拒绝", !sample(.nan, 500).validate(now: now))
        check("无限值拒绝", !sample(1, .infinity).validate(now: now))
        check("零额度拒绝", !sample(0, 0).validate(now: now))
        check("非法日期拒绝", !sample(1, 499, "2026-02-30").validate(now: now))
        check("倒序周期拒绝", !sample(1, 499, "2026-11-01", "2026-10-01").validate(now: now))
        check("未来时间拒绝", !sample(1, 499, "2026-10-01", "2026-11-01", now.addingTimeInterval(120)).validate(now: now))
        check("旧数据不被视为新数据", Freshness.isStale(usage: sample(1, 499, "2026-10-01", "2026-11-01", now.addingTimeInterval(-700)), now: now, interval: 300))
        check("正常 5 分钟刷新以内未过期", !Freshness.isStale(usage: sample(1, 499, "2026-10-01", "2026-11-01", now.addingTimeInterval(-300)), now: now, interval: 300))
        check("无数据标记未知", Freshness.isStale(usage: nil, now: now, interval: 300))
        check("1 分钟刷新有相应过期阈值", Freshness.isStale(usage: sample(1, 499, "2026-10-01", "2026-11-01", now.addingTimeInterval(-181)), now: now, interval: 60))
        check("剩余流量展示", DisplayMode.remainingGB.title(usage: usage) == "375.0G")
        check("已用流量展示", DisplayMode.usedGB.title(usage: usage) == "已用 125.0G")
        check("剩余百分比展示", DisplayMode.remainingPercent.title(usage: usage) == "75%")
        check("仅图标不重复数字", DisplayMode.icon.title(usage: usage) == "")
        check("未连接不伪造数字", DisplayMode.remainingGB.title(usage: nil) == "流量")
        print("\(count) native model tests passed")
    }
}
