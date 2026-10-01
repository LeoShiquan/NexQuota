#!/bin/zsh
set -eu
TASK_DIR="${0:A:h:h}"
mkdir -p "$TASK_DIR/.build/module-cache" "$TASK_DIR/docs/assets"
swiftc -O -swift-version 6 -warnings-as-errors -parse-as-library -D NEXQUOTA_DOCUMENTATION -module-cache-path "$TASK_DIR/.build/module-cache" "$TASK_DIR/Sources/Configuration.swift" "$TASK_DIR/Sources/Model.swift" "$TASK_DIR/Sources/WebSession.swift" "$TASK_DIR/Sources/MenuPlacement.swift" "$TASK_DIR/Sources/MenuPanel.swift" "$TASK_DIR/Sources/Main.swift" "$TASK_DIR/Scripts/render-doc-images.swift" -o "$TASK_DIR/.build/render-doc-images"
"$TASK_DIR/.build/render-doc-images" "$TASK_DIR/docs/assets"
