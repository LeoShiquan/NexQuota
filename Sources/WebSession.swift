import AppKit
import WebKit

@MainActor final class WebSession: NSObject, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
    let site: URL
    let webView: WKWebView
    let window: NSWindow
    var onPhase: ((Phase, String?) -> Void)?
    var onUsage: ((Usage) -> Void)?
    var onActivity: (() -> Void)?
    private var generation = 0
    private var reading = false
    private var busy = false
    private var documentFetchedAt = Date()
    private var lastPublishedGeneration = -1
    private var lastPublished: Usage?
    private var observationTimer: Timer?
    private let script: String
    init(site: URL) {
        self.site = site
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1060, height: 720), configuration: config)
        script = (try? String(contentsOf: Bundle.main.url(forResource: "usage-parser", withExtension: "js")!, encoding: .utf8)) ?? ""
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1060, height: 720), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "NexQuota · Nexitally 账户"; window.isReleasedWhenClosed = false
        window.contentView = webView; window.center(); window.delegate = self
        window.setFrameAutosaveName("NexQuota.Account")
        webView.navigationDelegate = self; webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        // This is a normal browser view. WebKit persists its own cookies for this App.
        // No browser-cookie import, password collection, or disabled certificate checks.
        observationTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.window.isVisible, !self.webView.isLoading else { return }
                self.inspect(attempt: 0, generation: self.generation, observing: true)
            }
        }
    }
    var isAccountVisible: Bool { window.isVisible }
    func showAccount() {
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        if webView.url == nil { refresh() }
    }
    func refresh() {
        guard !busy else { return }
        if window.isVisible, let url = webView.url,
           url.path.lowercased() != site.path.lowercased() {
            onPhase?(.login, "请先在账户窗口完成登录"); showAccount(); return
        }
        beginLoad()
    }
    private func beginLoad() {
        let request = URLRequest(url: site, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 40)
        webView.load(request)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        generation += 1; busy = true; onActivity?(); onPhase?(.loading, nil)
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self] in
            guard let self, self.generation == expected, self.busy else { return }
            self.generation += 1; self.busy = false; self.webView.stopLoading()
            self.onPhase?(.offline, "网站响应超时，稍后将自动重试")
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        documentFetchedAt = Date()
        inspect(attempt: 0, generation: generation, observing: false)
    }
    private func inspect(attempt: Int, generation expected: Int, observing: Bool) {
        guard !reading, expected == generation else { return }
        guard webView.url?.host?.lowercased() == site.host?.lowercased() else {
            busy = false; onPhase?(.login, "请在账户窗口登录 Nexitally"); return
        }
        reading = true
        let extract = script + """
        ;(() => {
          try { return {kind:'ready', usage:TrafficParser.parseDocument(document)}; }
          catch {
            const body = document.body?.innerText || '';
            if (/Just a moment|Attention Required|Checking your browser|请稍候/i.test(document.title) || /Verify you are human|验证您是人类/i.test(body)) return {kind:'verification'};
            if (/^[/]signin/i.test(location.pathname) || document.querySelector('input[type="password"]')) return {kind:'login'};
            const dashboardLink = document.querySelector('a[href*="Shadowsockes.aspx"]');
            return {kind:'unreadable', canNavigate: !!dashboardLink};
          }
        })()
        """
        webView.evaluateJavaScript(extract, in: nil, in: .world(name: "NexQuota.ReadOnly")) { [weak self] result in
            guard let self else { return }; self.reading = false
            guard self.generation == expected else {
                if self.busy && !self.webView.isLoading { self.inspect(attempt: 0, generation: self.generation, observing: false) }; return
            }
            switch result {
            case .success(let value):
                guard let object = value as? [String: Any], let kind = object["kind"] as? String else { self.failUnreadable(); return }
                if kind == "ready", let raw = object["usage"], let data = try? JSONSerialization.data(withJSONObject: raw),
                   let usage = try? JSONDecoder().decode(Usage.self, from: data), usage.validate() {
                    self.busy = false
                    if observing, self.lastPublishedGeneration == expected, let previous = self.lastPublished,
                       previous.usedGB == usage.usedGB, previous.remainingGB == usage.remainingGB,
                       previous.cycleStart == usage.cycleStart, previous.cycleEnd == usage.cycleEnd { return }
                    let captured = observing && self.lastPublishedGeneration == expected ? Date() : self.documentFetchedAt
                    let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let reading = Usage(usedGB: usage.usedGB, remainingGB: usage.remainingGB, cycleStart: usage.cycleStart, cycleEnd: usage.cycleEnd, capturedAt: formatter.string(from: captured))
                    self.lastPublished = reading; self.lastPublishedGeneration = expected
                    self.onUsage?(reading); self.onPhase?(.ready, nil)
                    return
                }
                if kind == "login" { self.busy = false; self.onPhase?(.login, "请在账户窗口完成 Nexitally 登录"); return }
                if kind == "verification" { self.busy = false; self.onPhase?(.verification, "网站需要验证，请在账户窗口完成验证"); return }
                if object["canNavigate"] as? Bool == true, self.webView.url?.path.lowercased() != self.site.path.lowercased() {
                    self.beginLoad(); return
                }
                if observing { return }
                if attempt < 12 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.inspect(attempt: attempt + 1, generation: expected, observing: false) }
                } else { self.failUnreadable() }
            case .failure:
                if !observing { self.failUnreadable() }
            }
        }
    }
    private func failUnreadable() { busy = false; onPhase?(.unreadable, "页面未提供流量数据，请检查账户登录和订阅状态") }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failNavigation(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failNavigation(error) }
    private func failNavigation(_ error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        generation += 1; busy = false
        onPhase?(.offline, "无法连接 Nexitally，请检查网络后刷新")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        generation += 1; busy = false; reading = false
        onPhase?(.offline, "网页进程已停止，下一次刷新会重新加载")
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame?.isMainFrame == true,
           let scheme = navigationAction.request.url?.scheme, scheme != "https" && scheme != "about" {
            decisionHandler(.cancel); onPhase?(.unreadable, "账户窗口仅支持 HTTPS 网页"); return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.scheme == "https" { webView.load(URLRequest(url: url)) }
        return nil
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool { sender.orderOut(nil); return false }
}
