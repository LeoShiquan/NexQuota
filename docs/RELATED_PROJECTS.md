# 同类项目与定位

[返回首页](../README.md)

## 对比依据

以下内容依据 2026 年 10 月 2 日检索到的公开仓库及其 README。对比的是项目声明的用途和数据来源；我们未安装这些工具，也未验证它们与 Nexitally 的实际兼容性。

| 项目 | 平台与形态 | 数据来源 | 与 NexQuota 的关系 |
| --- | --- | --- | --- |
| [SubStat](https://github.com/amirhp-com/SubStat) | 原生 Swift / SwiftUI macOS 菜单栏 App | `Subscription-Userinfo` 响应头；X-UI / 3X-UI HTML 模板作为补充 | 最接近的用途：剩余流量、到期时间与自动刷新；README 未声明 Nexitally 账户登录页适配 |
| [V2Ray Subscription Monitor](https://github.com/nimah79/v2ray-subscription-monitor) | Go + Fyne 桌面窗口和系统托盘；含 macOS 支持 | HTTP GET 读取订阅响应头 | 展示已用 / 总额与到期，并支持阈值及连续失败提醒 |
| [VPN 流量助手](https://github.com/wzzx888/vpn-traffic-helper) | Windows 图形工具 | 额度来自订阅响应头；路由器流量来自 SSH 读取 | 也关注机场计费额度，平台与交互形态不同 |
| [Mac-TrafficBar](https://github.com/Crossng/Mac-TrafficBar) | 原生 macOS 菜单栏 App | macOS 本机网络统计 | 展示网速、时间段流量与应用排行；统计口径与服务商账户额度不同 |

## NexQuota 聚焦什么

NexQuota 当前围绕一个 Nexitally 账户完成整条链路：加载账户网页 → 用户自行登录与验证 → 在本机维护 WebKit 会话 → 提取已用 / 剩余与套餐周期 → 校验并显示在菜单栏。

这让需要反复打开账户后台的用户，可以直接查看账户额度和更新时间。当前版本没有依赖订阅响应头，也不从本机网卡用量推算账户剩余额度。

如果服务商订阅本身提供有效额度响应头，响应头工具可能更直接。我们不据此推断 Nexitally 不支持这些响应头，也不承诺其他工具无法适配它。是否适用要按实际订阅和页面验证。

项目介绍围绕已实现的 Nexitally 账户页面适配，不宣称覆盖所有机场或是首个流量额度工具。未来新增适配先补足数据来源、状态处理和测试，再更新支持列表。

## 名称与致谢

Nex 来自 Nexitally，Quota 表示额度。名称对应第一版关注的账户与核心任务。NexQuota 是社区维护的非官方工具，与 Nexitally 无隶属或官方合作关系。

本机原型使用 TrafficBar 这个名字。公开前检索发现已有 [Windows TrafficBar](https://github.com/xev777/TrafficBar) 和 [Mac-TrafficBar](https://github.com/Crossng/Mac-TrafficBar)，因此公开项目采用 NexQuota，方便搜索和识别。此次 GitHub 名称检索未发现同名公开仓库；这只描述检索结果。

[CodexBar](https://github.com/steipete/CodexBar) 启发了菜单栏额度交互与文档组织。上面的同类项目帮助明确了数据来源和使用场景差异。NexQuota 沿用本项目的源码和图标，没有并入这些项目的代码或素材。
