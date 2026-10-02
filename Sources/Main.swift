import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor final class State: ObservableObject {
    @Published var usage: Usage?
    @Published var phase: Phase = .idle
    @Published var detail: String?
    @Published var now = Date()
    @Published var mode = DisplayMode(rawValue: UserDefaults.standard.string(forKey: "displayMode") ?? "") ?? .remainingGB
    @Published var interval: Int = { let value = UserDefaults.standard.integer(forKey: "refreshSeconds"); return [60,300,900,1800].contains(value) ? value : 300 }()
    @Published var loginItem = SMAppService.mainApp.status == .enabled
    @Published var loginItemError: String?
    var stale: Bool { Freshness.isStale(usage: usage, now: now, interval: TimeInterval(interval)) }
    var needsLogin: Bool { phase == .login || phase == .verification }
    var failed: Bool { [.offline, .unreadable, .login, .verification].contains(phase) }
    var status: String {
        if phase == .loading { return "正在更新流量…" }
        if let detail { return detail }
        if phase == .ready && !stale { return "已连接 · 每 \(interval / 60) 分钟自动更新" }
        if usage != nil && stale { return "数据未更新，请刷新或检查账户登录" }
        return "正在连接 Nexitally…"
    }
}
struct QuotaProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.18))
                Capsule().fill(.tint).frame(width: geometry.size.width * min(1, max(0, configuration.fractionCompleted ?? 0)))
            }
        }.frame(height: 8)
    }
}
struct UsagePanel: View {
    @ObservedObject var state: State
    let refresh: () -> Void
    let account: () -> Void
    let settings: () -> Void
    let quit: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "network").font(.system(size: 23)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nexitally").font(.system(size: 16, weight: .semibold))
                    Text("本月流量使用情况").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: settings) { Image(systemName: "gearshape") }.buttonStyle(.plain).help("设置").accessibilityLabel("设置")
            }
            if let usage = state.usage {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(String(format: "%.2f", usage.remainingGB)).font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit()
                    Text("GB 剩余").foregroundStyle(.secondary)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("本周期额度").font(.subheadline)
                        Spacer()
                        Text(String(format: "剩余 %.1f%%", usage.remainingFraction * 100)).font(.subheadline).monospacedDigit()
                    }
                    ProgressView(value: usage.remainingFraction).progressViewStyle(QuotaProgressStyle()).tint(usage.remainingFraction <= 0.1 ? .orange : .accentColor)
                        .accessibilityLabel("剩余流量比例").accessibilityValue(String(format: "%.1f%%", usage.remainingFraction * 100))
                    HStack {
                        Text(String(format: "已用 %.2f GB", usage.usedGB))
                        Spacer()
                        Text(String(format: "总计 %.0f GB", usage.totalGB))
                    }.font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("周期 \(usage.cycleStart) ～ \(usage.cycleEnd)")
                    if let days = usage.daysUntilEnd(now: state.now), days >= 0 { Text("距离周期截止约 \(days) 天") }
                    if let date = usage.date { Text("更新于 \(date.formatted(date: .abbreviated, time: .standard))") }
                }.font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.needsLogin ? "登录后开始监控" : "等待读取流量").font(.title3.weight(.semibold))
                    Text("在 App 的账户窗口中登录 Nexitally，完成后自动读取流量。会话保存在这台 Mac 上。")
                        .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 10)
            }
            HStack(alignment: .top, spacing: 7) {
                if state.phase == .loading { ProgressView().controlSize(.small).frame(width: 14, height: 14) }
                else { Image(systemName: state.failed || state.stale ? "exclamationmark.circle" : "checkmark.circle").foregroundStyle(state.failed ? Color.orange : Color.secondary) }
                Text(state.status).font(.caption).fixedSize(horizontal: false, vertical: true)
            }.frame(minHeight: 30, alignment: .topLeading).accessibilityElement(children: .combine)
            Divider()
            HStack(spacing: 12) {
                Button("刷新", action: refresh).disabled(state.phase == .loading).keyboardShortcut("r", modifiers: .command)
                Button(state.needsLogin ? "登录账户" : "查看账户", action: account)
                Spacer()
                Button(action: quit) { Image(systemName: "power") }.buttonStyle(.plain).help("退出 NexQuota").accessibilityLabel("退出 NexQuota")
            }
        }.padding(20).frame(width: 360)
    }
}
struct SettingsView: View {
    @ObservedObject var state: State
    let account: () -> Void
    let setLoginItem: @MainActor @Sendable (Bool) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text("NexQuota").font(.title2.weight(.semibold))
                Text("Nexitally 流量，随时可见").foregroundStyle(.secondary)
            }
            Form {
                Picker("菜单栏显示", selection: $state.mode) { ForEach(DisplayMode.allCases) { mode in Text(mode.label).tag(mode) } }
                Picker("自动刷新", selection: $state.interval) { ForEach([1,5,15,30], id: \.self) { minutes in Text("每 \(minutes) 分钟").tag(minutes * 60) } }
                Toggle("登录 Mac 时启动", isOn: Binding(get: { state.loginItem }, set: { enabled in setLoginItem(enabled) }))
            }
            if let error = state.loginItemError { Text(error).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true) }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Nexitally 账户").font(.headline)
                Text("登录会话由 App 内置浏览器保存在本机。会话过期或网站要求验证时，在账户窗口完成操作即可恢复更新。")
                    .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("打开账户窗口", action: account)
            }
            Text("NexQuota \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1.0") · 本机读取 · macOS 菜单栏应用").font(.caption).foregroundStyle(.secondary)
        }.padding(28).frame(width: 440)
    }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = State()
    var statusItem: NSStatusItem!
    var menuPanel: MenuPanelController!
    var session: WebSession!
    var settingsWindow: NSWindow?
    var subscriptions = Set<AnyCancellable>()
    var timer: Timer?
    var lastAttempt = Date.distantPast
    var promptedLogin = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let configuration: SiteConfiguration
        do { configuration = try SiteConfiguration.load() }
        catch {
            let alert = NSAlert(); alert.messageText = "NexQuota 站点配置不可用"
            alert.informativeText = error.localizedDescription; alert.addButton(withTitle: "退出")
            NSApp.activate(ignoringOtherApps: true); alert.runModal(); NSApp.terminate(nil); return
        }
        installMenu()
        if let data = UserDefaults.standard.data(forKey: "nativeUsage"), let usage = try? JSONDecoder().decode(Usage.self, from: data), usage.validate() { state.usage = usage }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = "NexQuota.Nexitally"
        statusItem.button?.target = self; statusItem.button?.action = #selector(toggle(_:))
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        statusItem.button?.imagePosition = .imageLeft
        menuPanel = MenuPanelController(content: UsagePanel(state: state, refresh: { [weak self] in self?.refresh() }, account: { [weak self] in self?.showAccount() }, settings: { [weak self] in self?.showSettings() }, quit: { NSApp.terminate(nil) }))
        session = WebSession(site: configuration.siteURL)
        session.onActivity = { [weak self] in self?.lastAttempt = Date() }
        session.onPhase = { [weak self] phase, detail in
            guard let self else { return }
            self.state.phase = phase; self.state.detail = detail; self.state.now = Date()
            if (phase == .login || phase == .verification), self.state.usage == nil, !self.promptedLogin {
                self.promptedLogin = true; self.session.showAccount()
            }
        }
        session.onUsage = { [weak self] usage in
            guard let self else { return }
            self.state.usage = usage; self.state.now = Date()
            if let data = try? JSONEncoder().encode(usage) { UserDefaults.standard.set(data, forKey: "nativeUsage") }
        }
        state.objectWillChange.sink { [weak self] in DispatchQueue.main.async { self?.updateTitle() } }.store(in: &subscriptions)
        state.$mode.dropFirst().sink { mode in UserDefaults.standard.set(mode.rawValue, forKey: "displayMode") }.store(in: &subscriptions)
        state.$interval.dropFirst().sink { interval in UserDefaults.standard.set(interval, forKey: "refreshSeconds") }.store(in: &subscriptions)
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.state.now = Date()
                if self.state.phase != .loading, !self.session.isAccountVisible,
                   Date().timeIntervalSince(self.lastAttempt) >= Double(self.state.interval) { self.refresh() }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
        updateTitle(); refresh()
    }
    @objc func woke() { if !session.isAccountVisible { refresh() } }
    func updateTitle() {
        let warning = state.usage != nil && (state.stale || state.failed)
        statusItem.button?.title = state.mode.title(usage: state.usage) + (warning ? " !" : "")
        statusItem.button?.image = meter(fraction: state.usage?.remainingFraction, dim: warning)
        statusItem.button?.toolTip = "Nexitally · \(state.mode.label) · \(state.status)"
        statusItem.button?.setAccessibilityLabel("Nexitally 流量，\(state.mode.title(usage: state.usage))，\(state.status)")
        menuPanel?.updateLayoutIfShown()
    }
    func meter(fraction: Double?, dim: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            NSColor.labelColor.withAlphaComponent(dim ? 0.5 : 1).set()
            let outline = NSBezierPath(roundedRect: NSRect(x: 1, y: 4, width: 16, height: 10), xRadius: 2, yRadius: 2)
            outline.lineWidth = 1.4; outline.stroke()
            if let fraction, fraction > 0 {
                NSBezierPath(roundedRect: NSRect(x: 3, y: 6, width: max(1, min(1, fraction) * 12), height: 6), xRadius: 1, yRadius: 1).fill()
            } else if fraction == nil { NSBezierPath(rect: NSRect(x: 6, y: 8, width: 6, height: 2)).fill() }
            return true
        }
        image.isTemplate = true; return image
    }
    @objc func toggle(_ sender: Any?) {
        if menuPanel.isShown { menuPanel.close() }
        else { showMenu(relativeTo: (sender as? NSStatusBarButton) ?? statusItem.button) }
    }
    func showMenu(relativeTo button: NSStatusBarButton?) {
        guard let button else { return }
        state.now = Date(); menuPanel.show(relativeTo: button)
    }
    func installMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "NexQuota")
        for (title, action, key) in [
            ("显示/隐藏流量", #selector(toggle(_:)), "t"),
            ("刷新流量", #selector(refresh), "r"),
            ("查看账户…", #selector(showAccount), "l"),
            ("设置…", #selector(showSettings), ",")
        ] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.target = self; appMenu.addItem(item)
        }
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        appMenu.addItem(NSMenuItem(title: "退出 NexQuota", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu; menu.addItem(appItem); NSApp.mainMenu = menu
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMenu(relativeTo: statusItem.button); return false
    }
    @objc func refresh() { lastAttempt = Date(); session.refresh() }
    @objc func showAccount() { menuPanel.close(); session.showAccount() }
    @objc func showSettings() {
        menuPanel.close()
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView(state: state, account: { [weak self] in self?.showAccount() }, setLoginItem: { [weak self] value in self?.setLoginItem(value) }))
            let window = NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable]; window.title = "NexQuota · 设置"; window.isReleasedWhenClosed = false; window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func setLoginItem(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            state.loginItem = SMAppService.mainApp.status == .enabled
            state.loginItemError = SMAppService.mainApp.status == .requiresApproval ? "请在系统设置 → 通用 → 登录项中允许 NexQuota。" : nil
        } catch { state.loginItem = SMAppService.mainApp.status == .enabled; state.loginItemError = "开机启动设置失败。请把 App 放在固定位置后重试，也可在系统登录项中手动添加。" }
    }
    func applicationWillTerminate(_ notification: Notification) {
        menuPanel?.close()
        timer?.invalidate()
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
    }
}
#if !NEXQUOTA_DOCUMENTATION
@main struct Main {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        withExtendedLifetime(delegate) { app.delegate = delegate; app.run() }
    }
}
#endif
