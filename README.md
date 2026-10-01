# NexQuota

> Nexitally 流量额度，抬头就能看见。

<img src="docs/assets/badges.svg" alt="macOS 13+ 构建目标 · Apple Silicon · Swift 6 · MIT" width="538" />

[English](README.en.md) · [使用指南](docs/USAGE.md) · [设计原理](docs/DESIGN.md) · [隐私说明](docs/PRIVACY.md) · [同类项目](docs/RELATED_PROJECTS.md) · [参与贡献](CONTRIBUTING.md)

<img src="docs/assets/hero.png" alt="NexQuota 演示场景：菜单栏显示 375.0G，流量面板显示剩余 375 GB 和套餐周期" width="100%" />

NexQuota 是一个用于查看 **Nexitally 账户用量** 的原生 macOS 菜单栏工具。打开一次内置账户窗口，完成网站登录与验证，之后便可从菜单栏查看剩余流量、已用流量和套餐周期，并定时刷新。

**社区维护的非官方工具，当前聚焦单个 Nexitally 账户。** 项目与 Nexitally 无隶属或官方合作关系。站点地址由你在本地配置；其他机场需要单独适配。显示的是服务商后台统计的计费流量，默认每 5 分钟更新。

*本页界面图使用固定演示数据，未连接真实账户。原生视图截图与封面背景的说明见 [图片来源](docs/assets/README.md)。*

## 为什么做 NexQuota

查一次剩余流量，常常需要打开浏览器、找到账户页，再从页面里寻找用量。NexQuota 把这个重复操作缩短为看一眼菜单栏：剩余额度是否充足、当前周期什么时候结束、这份数据多久前更新，都在同一个小面板里。

项目受 [CodexBar](https://github.com/steipete/CodexBar) 的菜单栏用量展示启发，采用 Swift、SwiftUI 和 WebKit 实现。目标是让额度容易查看、让数据来源清楚、让账户会话留在本机。

## 功能

| 功能 | 具体表现 |
| --- | --- |
| 菜单栏用量 | 剩余 GB、剩余百分比、已用 GB、已用百分比或仅图标 |
| 套餐详情 | 剩余与已用流量、总额度、周期起止日期及剩余天数 |
| 自动刷新 | 1 / 5 / 15 / 30 分钟可选，也可手动刷新；Mac 唤醒后重新读取 |
| 账户登录 | 在 App 内置网页中登录，并自行完成网站要求的验证 |
| 数据状态 | 展示更新时间；连接失败时保留最近一次成功数据，并提示状态 |
| 原生交互 | 点击外部、再次点击图标或按 Escape 关闭面板；菜单位于菜单栏下方 |
| 开机启动 | 可在设置中启用“登录 Mac 时启动” |

## 界面

<table>
<tr><th>流量面板</th><th>设置窗口</th></tr>
<tr>
<td valign="top"><img src="docs/assets/menu.png" alt="演示流量：已用 125 GB，剩余 375 GB，总额 500 GB" width="360" /></td>
<td valign="top"><img src="docs/assets/settings.png" alt="NexQuota 设置：菜单栏显示方式、刷新间隔和开机启动" width="440" /></td>
</tr>
</table>

流量数值与周期是演示数据。设置截图没有账号、邮箱、真实站点地址或个人订阅链接。

## 从源码构建

当前提供源码与本机编译方式。构建脚本使用本地 ad-hoc 签名，不需要 Apple Developer Program 会员。

需要一台 Apple Silicon Mac、Swift 6 工具链及 macOS SDK。运行测试还需要 Node.js。构建目标为 macOS 13+；完整的兼容性与验证范围见 [开发指南](docs/DEVELOPMENT.md)。

1. 下载或克隆本仓库，进入 `NexQuota` 目录。
2. 复制示例配置，并用文本编辑器打开副本：

   ```bash
   cp Config.example.plist Config.local.plist
   ```

3. 将 `SiteURL` 的示例地址改成自己的 **HTTPS 账户用量页** 地址，例如你登录后可以看到“已使用流量 / 未使用流量”的页面。示例域名 `panel.example.com` 只是占位符。`Config.local.plist` 已被 Git 忽略。
4. 编译并检查：

   ```bash
   ./build.sh
   ./test.sh
   ```

5. 用 Finder 打开项目下的 `.build` 文件夹，双击 `NexQuota.app`。如需开机启动，先将 App 放到固定位置，再启用对应选项。

站点配置会复制进你本机编译的 App。请勿把含有私人地址的构建产物作为公开文件提交。

## 第一次使用

1. 启动后在菜单栏找到 NexQuota。首次连接需要登录时，App 会打开账户窗口。
2. 在内置网页中自行登录并完成网站验证；App 不代填或保存密码字段。
3. 读取到有效用量后，关闭账户窗口。App 将按设置的间隔在后台刷新。
4. 点击菜单栏查看详情；齿轮可调整显示方式、刷新间隔和开机启动。
5. 登录过期时点击“登录账户”或“查看账户”，在账户窗口重新完成登录。

账户窗口打开时暂停定时重新加载，避免打断你操作网页。详细快捷键、异常状态和升级步骤见 [使用指南](docs/USAGE.md)。

## 数据与隐私

- 流量读取在本机完成，项目没有自建的中转服务或遥测收集端点。
- 登录网页会正常连接你配置的服务商及其网页依赖；服务商会按其规则处理登录信息。
- 登录会话由 WebKit 的本机数据存储管理。App 不导入 Chrome 或 Safari 的 Cookie。
- App 只缓存已用/剩余流量、周期和读取时间，不保存原始账户页面或密码字段。
- 网页提取在独立的 WebKit 内容环境中运行；读取到的数值和日期经过校验后才展示。

详见 [隐私与数据流](docs/PRIVACY.md)。

## 当前范围与限制

- 首批适配 Nexitally；填写其他网站地址不会自动获得对该网站的支持。
- 后台计费统计可能有延迟，菜单栏展示不等同于实时网速。
- 网站调整用量标签、页面结构或验证流程后，可能需要更新适配代码。
- 目前维护单个账户；历史曲线、阈值通知和多机场管理尚未实现。
- 当前构建产物面向 Apple Silicon；Intel、Windows、Linux 不在本版验证范围内。

## 同类项目与差异

订阅额度查询已经有开源实现。NexQuota 聚焦 Nexitally 的网页登录、验证、本机会话和账户用量读取流程。

| 项目 | 主要用途与数据来源 |
| --- | --- |
| [SubStat](https://github.com/amirhp-com/SubStat) | 原生 macOS 菜单栏额度展示；读取订阅响应头，兼容 X-UI / 3X-UI HTML 模板 |
| [V2Ray Subscription Monitor](https://github.com/nimah79/v2ray-subscription-monitor) | Go + Fyne 桌面与托盘工具；读取订阅响应头，提供用量与失败提醒 |
| [Mac-TrafficBar](https://github.com/Crossng/Mac-TrafficBar) | macOS 本机网速、网络流量与应用排行；读取系统网络统计 |

如果订阅本身提供可用的额度响应头，上述响应头工具可能更直接。我们没有验证它们与 Nexitally 的实际兼容性。详细数据来源、对比范围与命名说明见 [同类项目](docs/RELATED_PROJECTS.md)。

## 项目文档

| 文档 | 内容 |
| --- | --- |
| [使用指南](docs/USAGE.md) | 登录、刷新、快捷键、常见问题和卸载 |
| [设计原理](docs/DESIGN.md) | 项目目的、信息层级、交互取舍与视觉规范 |
| [架构说明](docs/ARCHITECTURE.md) | 模块职责、读取流程、数据校验和多屏定位 |
| [隐私说明](docs/PRIVACY.md) | 本机存储、网络连接和公开素材脱敏 |
| [开发指南](docs/DEVELOPMENT.md) | 编译、测试、目录结构与新增适配的入口 |
| [同类项目](docs/RELATED_PROJECTS.md) | 已有工具、数据来源差异与项目命名 |
| [更新记录](CHANGELOG.md) | 版本变化和实现边界 |

## 参与贡献

欢迎改进页面适配、修复菜单栏交互问题、补充测试和完善文档。开始前请阅读 [贡献指南](CONTRIBUTING.md)。提 Issue 或 PR 时，请使用虚构数据并移除私人链接及登录信息。

## 许可证与致谢

采用 [MIT License](LICENSE)。感谢 [CodexBar](https://github.com/steipete/CodexBar) 对菜单栏用量工具的交互启发。NexQuota 保留自己的名称、图标与实现。
