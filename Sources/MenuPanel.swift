import AppKit
import SwiftUI

@MainActor private final class TrafficMenuWindow: NSPanel {
    var dismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { dismiss?() }
}

@MainActor final class MenuPanelController: NSObject {
    private let panel: TrafficMenuWindow
    private let hosting: NSHostingView<UsagePanel>
    private let scroll = NSScrollView()
    private weak var anchorButton: NSStatusBarButton?
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(content: UsagePanel) {
        hosting = NSHostingView(rootView: content)
        panel = TrafficMenuWindow(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.title = "NexQuota · 菜单"
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = true
        panel.level = .popUpMenu; panel.animationBehavior = .none
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
        panel.dismiss = { [weak self] in self?.close() }

        let background = NSVisualEffectView()
        background.material = .menu; background.blendingMode = .behindWindow; background.state = .active
        background.wantsLayer = true; background.layer?.cornerRadius = 14; background.layer?.masksToBounds = true
        scroll.drawsBackground = false; scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true; scroll.scrollerStyle = .overlay
        scroll.autoresizingMask = [.width, .height]; scroll.documentView = hosting
        background.addSubview(scroll); panel.contentView = background
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: NSApplication.didResignActiveNotification, object: NSApp)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayoutIfShown), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    var isShown: Bool { panel.isVisible }

    func show(relativeTo button: NSStatusBarButton) {
        anchorButton = button
        guard updateLayout() else { return }
        // Take keyboard focus without raising the app's account or settings windows on other displays.
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        installDismissMonitors()
    }

    @objc func updateLayoutIfShown() {
        if isShown, !updateLayout() { close() }
    }

    @discardableResult private func updateLayout() -> Bool {
        guard let button = anchorButton, let window = button.window, let screen = window.screen else { return false }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        hosting.layoutSubtreeIfNeeded()
        let contentSize = hosting.fittingSize
        guard contentSize.width > 0, contentSize.height > 0 else { return false }
        let frame = MenuPlacement.frame(contentSize: contentSize, anchor: anchor, visibleFrame: screen.visibleFrame)
        hosting.frame = NSRect(origin: .zero, size: NSSize(width: frame.width, height: contentSize.height))
        panel.setFrame(frame, display: true)
        scroll.frame = panel.contentView?.bounds ?? .zero
        return true
    }

    private func anchorContains(_ point: NSPoint) -> Bool {
        guard let button = anchorButton, let window = button.window else { return false }
        return window.convertToScreen(button.convert(button.bounds, to: nil)).contains(point)
    }

    private func installDismissMonitors() {
        removeDismissMonitors()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                let point = NSEvent.mouseLocation
                if !self.panel.frame.contains(point), !self.anchorContains(point) { self.close() }
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    private func removeDismissMonitors() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }; globalMonitor = nil
    }

    @objc func close() { panel.orderOut(nil); removeDismissMonitors() }
}
