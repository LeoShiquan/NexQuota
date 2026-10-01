import Foundation
import CoreGraphics

enum MenuPlacement {
    static let gap: CGFloat = 8
    static let edgeMargin: CGFloat = 8

    static func frame(contentSize: CGSize, anchor: CGRect, visibleFrame: CGRect) -> CGRect {
        let width = min(contentSize.width, max(1, visibleFrame.width - edgeMargin * 2))
        let height = min(contentSize.height, max(1, visibleFrame.height - gap - edgeMargin))
        let x = min(max(anchor.midX - width / 2, visibleFrame.minX + edgeMargin), visibleFrame.maxX - edgeMargin - width)
        let top = min(anchor.minY, visibleFrame.maxY) - gap
        let y = max(visibleFrame.minY + edgeMargin, min(top - height, visibleFrame.maxY - gap - height))
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
