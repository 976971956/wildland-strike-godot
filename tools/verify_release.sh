#!/bin/sh
set -eu

release_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
release_godot=${GODOT_BIN:-godot}

cd "$release_root"
mkdir -p build/web build/ios

"$release_godot" --headless --log-file /tmp/wildland-release-import.log --path . --import
"$release_godot" --headless --log-file /tmp/wildland-release-tests.log --path . --script tests/test_runner.gd
"$release_godot" --headless --log-file /tmp/wildland-release-web.log --path . --export-debug Web build/web/index.html
"$release_godot" --headless --log-file /tmp/wildland-release-ios.log --path . --export-debug "iOS Device Debug" build/ios/WildlandStrike

if command -v xcodebuild >/dev/null 2>&1; then
	DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
	export DEVELOPER_DIR
	xcodebuild \
		-project build/ios/WildlandStrike.xcodeproj \
		-scheme WildlandStrike \
		-configuration Debug \
		-sdk iphoneos \
		-destination 'generic/platform=iOS' \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY= \
		build
fi
