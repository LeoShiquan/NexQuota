# 开发指南

[返回首页](../README.md)

## 环境

- Apple Silicon Mac；Swift 6 工具链及 macOS SDK。
- Node.js，用于运行网页解析测试。
- Git，用于版本管理。
- 可选 Python 3 / Node.js，用于文档排版工具；正常构建不需要它们。

构建目标为 `arm64-apple-macosx13.0`。本次本地验证使用 Swift 6.4 和 Apple Silicon 开发机；macOS 13 最低版本、所有屏幕配置与 Intel 运行环境尚未完成系统验证。不要把构建目标误认为完整兼容性测试结果。

## 本机编译

```bash
cp Config.example.plist Config.local.plist
# 使用文本编辑器将 SiteURL 改为自己的账户用量页地址
./build.sh
./test.sh
```

输出为 `.build/NexQuota.app`，使用 ad-hoc 签名，仅用于从源码构建。构建不会自动复制到应用程序目录或启动 App。没有 Apple Developer ID 签名、公证或下载安装脚本。

运行测试共 55 项：网页解析 15、数据模型 21、菜单定位 9、配置验证 10。构建产物还会进行严格签名校验和 Info.plist 语法校验。测试不需要真实账号，不连接服务商。

可以用 `NEXQUOTA_APP_DIR` 修改构建输出位置；运行 `test.sh` 时使用同一个值即可。

## 目录

```text
NexQuota/
├── Sources/                 原生 App 与业务模型
├── Resources/               网页解析器与 App 图标
├── Tests/                   虚构数据与定位、配置测试
├── Scripts/                 可复现的文档截图生成
├── docs/                    使用、设计、架构和隐私说明
│   ├── assets/              已脱敏的公开素材
│   └── preview/             本地 README 预览
├── .github/                 问题模板、PR 模板与 CI
├── Config.example.plist     无真实凭据的示例配置
├── Config.local.plist       本机创建，不纳入 Git
├── build.sh
└── test.sh
```

## 新增网站适配

目前还没有通用插件接口。新增适配先明确站点的数据来源，再修改 WebSession 的状态识别与解析器；用合成样本覆盖成功、登录、验证、缺少字段与页面改变的情况。

保持 Usage 的已用 / 剩余 / 周期 / 读取时间约定，复用原生展示和新鲜度逻辑。不要为了让样本通过而跳过校验或硬编码真实账户数字。

## 生成公开图片

```bash
./Scripts/render-doc-images.sh
```

这个脚本编译文档专用入口，用固定状态渲染 App 原生视图，输出 `menu.png`、`settings.png` 和 `stale.png`。不创建账户网页，也不会改动开机启动。截图样本定义在 `Scripts/render-doc-images.swift`。

封面、徽章与 README 本地预览由 `Scripts/compose-docs.py` 生成。它使用 Python 3 标准库、本机 Swift / WebKit 和 Node.js 的 marked 开发依赖。正常编译 App 不依赖这些文档工具。

```bash
npm install --prefix Scripts
python3 Scripts/compose-docs.py
```

更新 README 后，应重新生成预览并核对相对链接。预览首页图截取项目介绍、功能与界面区域，完整长图与可滚动 HTML 位于 `docs/preview/`。

## 自动检查

`.github/workflows/check.yml` 在 macOS runner 上编译和运行测试，只使用占位配置，不需要私有凭据。CI 不上传 App 安装包；首次 GitHub 执行结果应在仓库公开后核验。

文档与公开文件检查使用 `python3 Scripts/check-public-files.py`。检查覆盖相对链接、必需文件、占位配置和常见私密数据模式，但不能替代人工检查图片。
