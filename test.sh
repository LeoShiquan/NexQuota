#!/bin/zsh
set -eu
TASK_DIR="${0:A:h}"
APP_DIR="${NEXQUOTA_APP_DIR:-$TASK_DIR/.build/NexQuota.app}"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nexquota-check.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TASK_DIR/.build/test-module-cache"
node "$TASK_DIR/Tests/parser.test.js"
swiftc -swift-version 6 -warnings-as-errors -parse-as-library -module-cache-path "$TASK_DIR/.build/test-module-cache" "$TASK_DIR/Sources/Model.swift" "$TASK_DIR/Tests/model.test.swift" -o "$TEST_DIR/model-tests"
"$TEST_DIR/model-tests"
swiftc -swift-version 6 -warnings-as-errors -parse-as-library -module-cache-path "$TASK_DIR/.build/test-module-cache" "$TASK_DIR/Sources/MenuPlacement.swift" "$TASK_DIR/Tests/menu-placement.test.swift" -o "$TEST_DIR/menu-placement-tests"
"$TEST_DIR/menu-placement-tests"
swiftc -swift-version 6 -warnings-as-errors -parse-as-library -module-cache-path "$TASK_DIR/.build/test-module-cache" "$TASK_DIR/Sources/Configuration.swift" "$TASK_DIR/Tests/configuration.test.swift" -o "$TEST_DIR/configuration-tests"
"$TEST_DIR/configuration-tests"
codesign --verify --deep --strict "$APP_DIR"
plutil -lint "$APP_DIR/Contents/Info.plist"
