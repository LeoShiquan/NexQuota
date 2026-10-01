# 图片来源与脱敏

| 文件 | 来源与内容 |
| --- | --- |
| `menu.png` | 本项目 UsagePanel 原生 SwiftUI 视图，固定虚构的 125 GB / 375 GB 用量 |
| `settings.png` | 本项目 SettingsView 原生 SwiftUI 视图，固定默认选项，不操作系统登录项 |
| `stale.png` | 同一流量视图，演示读取时间过期时的状态 |
| `hero.png` | 文档封面：本项目图标、原生流量视图截图和示意菜单栏背景排版 |
| `badges.svg` | 本项目生成的本地徽章，不依赖远程图片请求 |
| `AppIcon.png` | 为 NexQuota 生成的项目图标；源 App 图标位于 Resources |

所有截图生成过程不创建 WebSession，不读取真实账号、页面、Cookie 或桌面截图。公开图像采用演示数据，未包含私人网址、邮箱或个人窗口。

原生视图渲染脚本为 `Scripts/render-doc-images.swift`，构图与预览工具为 `Scripts/compose-docs.py`。图标为本项目生成，没有使用 CodexBar 的图标或标识。项目素材随本仓库采用 MIT 许可证。

图示使用蓝绿色强调色；App 的实际强调色可随 macOS 设置变化。

公开 PNG 与 ICNS 内嵌图片已移除文本、EXIF、内容凭据及其他非视觉元数据；ICNS 的可选工具信息也已移除。保留像素、色彩和显示分辨率信息。
