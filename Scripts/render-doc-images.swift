import AppKit
import SwiftUI

// Render the app's own SwiftUI views with synthetic data. No WebSession is created.
@main struct DocumentationImages {
    @MainActor static func capture<Content: View>(_ content: Content, width: CGFloat, path: URL) throws {
        let renderer = ImageRenderer(content: content
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .environment(\.colorScheme, .light)
            .environment(\.controlActiveState, .key)
            .accentColor(Color(red: 0.04, green: 0.48, blue: 0.50))
            .background(Color(nsColor: .windowBackgroundColor)))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        renderer.scale = 2; renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: path)
        print("Rendered \(path.lastPathComponent): \(bitmap.pixelsWide) × \(bitmap.pixelsHigh)")
    }

    @MainActor static func main() throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.appearance = NSAppearance(named: .aqua)
        guard CommandLine.arguments.count == 2 else { throw CocoaError(.fileWriteInvalidFileName) }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let state = State()
        let now = ISO8601DateFormatter().date(from: "2026-10-02T10:00:00Z")!
        state.now = now; state.mode = .remainingGB; state.interval = 300
        state.loginItem = false; state.loginItemError = nil; state.phase = .ready; state.detail = nil
        state.usage = Usage(usedGB: 125, remainingGB: 375, cycleStart: "2026-10-01", cycleEnd: "2026-11-01", capturedAt: "2026-10-02T10:00:00Z")
        let panel = UsagePanel(state: state, refresh: {}, account: {}, settings: {}, quit: {})
        try capture(panel, width: 360, path: output.appendingPathComponent("menu.png"))
        try capture(SettingsView(state: state, account: {}, setLoginItem: { _ in }), width: 440, path: output.appendingPathComponent("settings.png"))
        state.now = now.addingTimeInterval(3600)
        try capture(panel, width: 360, path: output.appendingPathComponent("stale.png"))
    }
}
