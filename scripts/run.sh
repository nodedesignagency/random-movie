#!/usr/bin/env bash
# Builds Reel and opens it in the iOS Simulator.
#   ./scripts/run.sh                    # iPhone 17 Pro
#   ./scripts/run.sh "iPhone 17"        # any simulator by name
#   ./scripts/run.sh "iPhone 17 Pro" -ReelAutoPick YES   # extra launch arguments
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 17 Pro}"
shift || true
BUNDLE=com.nodedesign.reel
APP=build/Build/Products/Debug-iphonesimulator/Reel.app

# The newest available simulator with that name (runtimes are listed oldest first).
UDID=$(xcrun simctl list devices available | grep -F "    $DEVICE (" | tail -1 | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)
if [ -z "$UDID" ]; then
  echo "No simulator called \"$DEVICE\". Available iPhones:"
  xcrun simctl list devices available | grep -E '^\s+iPhone' || true
  exit 1
fi

echo "› Booting $DEVICE"
open -a Simulator
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b > /dev/null

echo "› Building (the first build takes a minute or two)"
xcodebuild -project Reel.xcodeproj -scheme Reel -configuration Debug \
  -destination "id=$UDID" -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "› Installing and launching"
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BUNDLE" "$@" > /dev/null
echo "✓ Reel is running in the Simulator"
