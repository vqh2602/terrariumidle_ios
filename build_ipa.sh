#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_ipa.sh [export_method]
# export_method: development (default), ad-hoc, app-store-connect, enterprise
EXPORT_METHOD="${1:-development}"

PROJECT="terrariumidle_ios.xcodeproj"
SCHEME="terrariumidle_ios"
CONFIGURATION="Release"
TEAM_ID="5KS3F42MTD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/terrariumidle_ios.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
IPA_NAME="terrariumidle_ios.ipa"
FIXED_IPA_NAME="terrariumidle_fixed.ipa"

echo "==> [1/4] Cleaning previous build artifacts..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$SCRIPT_DIR/ipa_fix" "$SCRIPT_DIR/$IPA_NAME" "$SCRIPT_DIR/$FIXED_IPA_NAME"
mkdir -p "$BUILD_DIR" "$EXPORT_DIR"

echo "==> [2/4] Generating ExportOptions.plist (method: $EXPORT_METHOD)..."
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

echo "==> [3/4] Archiving $SCHEME ($CONFIGURATION)..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

echo "==> Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates

EXPORTED_IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name "*.ipa" | head -n 1)"
if [[ -z "$EXPORTED_IPA" || ! -f "$EXPORTED_IPA" ]]; then
    echo "Error: No .ipa file found in $EXPORT_DIR" >&2
    exit 1
fi

cp "$EXPORTED_IPA" "$SCRIPT_DIR/$IPA_NAME"
echo "    Exported: $SCRIPT_DIR/$IPA_NAME"

echo "==> [4/4] Fixing IPA (removing Watch app)..."
mkdir -p ipa_fix
unzip -q "$IPA_NAME" -d ipa_fix
rm -rf ipa_fix/Payload/terrariumidle_ios.app/Watch
cd ipa_fix
zip -qry "../$FIXED_IPA_NAME" Payload
cd ..

echo "==> Done!"
echo "    Original IPA : $SCRIPT_DIR/$IPA_NAME"
echo "    Fixed IPA    : $SCRIPT_DIR/$FIXED_IPA_NAME"
