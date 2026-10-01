#!/bin/zsh
set -eu
TASK_DIR="${0:A:h}"
APP_DIR="${NEXQUOTA_APP_DIR:-$TASK_DIR/.build/NexQuota.app}"
CONFIG_FILE="$TASK_DIR/Config.local.plist"
if [[ ! -f "$CONFIG_FILE" ]]; then
    print -u2 '缺少 Config.local.plist。请复制 Config.example.plist 并填写自己的 HTTPS 账户用量页地址。'
    exit 1
fi
plutil -lint "$CONFIG_FILE"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$TASK_DIR/.build/module-cache"
cp "$TASK_DIR/Resources/usage-parser.js" "$APP_DIR/Contents/Resources/usage-parser.js"
cp "$TASK_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$CONFIG_FILE" "$APP_DIR/Contents/Resources/SiteConfig.plist"
swiftc -O -swift-version 6 -warnings-as-errors -parse-as-library -module-cache-path "$TASK_DIR/.build/module-cache" -target arm64-apple-macosx13.0 "$TASK_DIR/Sources/Configuration.swift" "$TASK_DIR/Sources/Model.swift" "$TASK_DIR/Sources/WebSession.swift" "$TASK_DIR/Sources/MenuPlacement.swift" "$TASK_DIR/Sources/MenuPanel.swift" "$TASK_DIR/Sources/Main.swift" -o "$APP_DIR/Contents/MacOS/NexQuota"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleName</key><string>NexQuota</string><key>CFBundleDisplayName</key><string>NexQuota</string><key>CFBundleIdentifier</key><string>local.nexquota.app</string><key>CFBundleExecutable</key><string>NexQuota</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleIconFile</key><string>AppIcon.icns</string><key>CFBundleVersion</key><string>7</string><key>CFBundleShortVersionString</key><string>2.1.0</string><key>LSUIElement</key><true/><key>LSMinimumSystemVersion</key><string>13.0</string><key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_DIR"
print 'Built NexQuota 2.1.0 (source build, ad-hoc signed, Apple Silicon, macOS 13+ target)'
