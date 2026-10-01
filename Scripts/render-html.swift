import AppKit
import WebKit
import Darwin

// Local document export only. This renderer never opens a user browser or a provider page.
@MainActor final class DocumentSnapshot: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let window: NSWindow
    private let input: URL
    private let output: URL
    private let width: CGFloat
    private let requestedHeight: CGFloat

    init(input: URL, output: URL, width: CGFloat, height: CGFloat) {
        self.input = input; self.output = output; self.width = width; requestedHeight = height
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height > 0 ? height : 1000), configuration: configuration)
        window = NSWindow(contentRect: webView.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        super.init()
        window.contentView = webView; window.appearance = NSAppearance(named: .aqua)
        webView.navigationDelegate = self
    }

    func start() {
        let root = input.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        webView.loadFileURL(input, allowingReadAccessTo: root)
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { print("Local document render timed out"); exit(1) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let measure = requestedHeight == -1
            ? "Math.ceil([...document.querySelectorAll('h2')].find(x => x.textContent === '从源码构建').getBoundingClientRect().top - 16)"
            : "Math.ceil(document.documentElement.scrollHeight)"
        webView.evaluateJavaScript(measure) { [weak self] result, error in
            guard let self, error == nil, let measured = result as? NSNumber else { print("Cannot measure document"); exit(1) }
            let height = self.requestedHeight > 0 ? self.requestedHeight : CGFloat(truncating: measured)
            self.window.setContentSize(NSSize(width: self.width, height: height))
            self.webView.frame = NSRect(x: 0, y: 0, width: self.width, height: height)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let options = WKSnapshotConfiguration()
                options.rect = self.webView.bounds; options.snapshotWidth = NSNumber(value: Double(self.width) * 2)
                self.webView.takeSnapshot(with: options) { image, error in
                    guard error == nil, let image, let tiff = image.tiffRepresentation,
                          let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) else {
                        print("Cannot export document snapshot"); exit(1)
                    }
                    do { try png.write(to: self.output) }
                    catch { print("Cannot save document snapshot"); exit(1) }
                    print("Rendered \(self.output.lastPathComponent): \(bitmap.pixelsWide) × \(bitmap.pixelsHigh)")
                    exit(0)
                }
            }
        }
    }
}

@main struct ExportLocalDocument {
    @MainActor static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 5, let width = Double(arguments[3]), let height = Double(arguments[4]) else { exit(2) }
        let app = NSApplication.shared; app.setActivationPolicy(.accessory)
        let snapshot = DocumentSnapshot(input: URL(fileURLWithPath: arguments[1]), output: URL(fileURLWithPath: arguments[2]), width: CGFloat(width), height: CGFloat(height))
        withExtendedLifetime(snapshot) { snapshot.start(); app.run() }
    }
}
