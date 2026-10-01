import Foundation
import CoreGraphics

@main struct MenuPlacementTests {
    static func main() {
        var passed = 0
        func check(_ label: String, _ condition: Bool) {
            precondition(condition, label)
            passed += 1; print("PASS \(label)")
        }
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 950)
        let size = CGSize(width: 360, height: 390)
        let center = MenuPlacement.frame(contentSize: size, anchor: CGRect(x: 720, y: 950, width: 70, height: 32), visibleFrame: visible)
        check("菜单完全位于菜单栏下方，顶部至少留 8 点", center.maxY <= visible.maxY - 8)
        check("普通屏幕保持面板完整尺寸", center.size == size)
        check("左侧按钮不会使菜单越过左边缘", visible.contains(MenuPlacement.frame(contentSize: size, anchor: CGRect(x: 0, y: 950, width: 50, height: 32), visibleFrame: visible)))
        check("右侧按钮不会使菜单越过右边缘", visible.contains(MenuPlacement.frame(contentSize: size, anchor: CGRect(x: 1490, y: 950, width: 22, height: 32), visibleFrame: visible)))
        let negativeScreen = CGRect(x: -1920, y: 180, width: 1920, height: 1048)
        let negative = MenuPlacement.frame(contentSize: size, anchor: CGRect(x: -900, y: 1228, width: 60, height: 32), visibleFrame: negativeScreen)
        check("左侧外接屏使用自身坐标", negativeScreen.contains(negative) && negative.maxX < 0)
        check("外接屏也保留顶部间距", negative.maxY <= negativeScreen.maxY - 8)
        let upperScreen = CGRect(x: 1512, y: 982, width: 1280, height: 770)
        let upper = MenuPlacement.frame(contentSize: size, anchor: CGRect(x: 2300, y: 1752, width: 60, height: 32), visibleFrame: upperScreen)
        check("不同纵向原点的屏幕不会落回主屏幕", upperScreen.contains(upper))
        let small = CGRect(x: 0, y: 0, width: 300, height: 300)
        let constrained = MenuPlacement.frame(contentSize: size, anchor: CGRect(x: 130, y: 300, width: 40, height: 30), visibleFrame: small)
        check("小屏幕或过长内容也保持在可见区域内", small.contains(constrained))
        check("过长内容为滚动视图留出受限高度", constrained.height < size.height)
        print("\(passed) menu placement tests passed")
    }
}
