#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/threemonthcal/threemonthcal.xcodeproj"
SCHEME="threemonthcal"
CONFIGURATION="Release"
ARCHIVE_PATH="$ROOT/build/${SCHEME}.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_OPTIONS="$ROOT/scripts/ExportOptions.plist"
APP_PATH="$EXPORT_PATH/${SCHEME}.app"
ZIP_PATH="$ROOT/build/${SCHEME}.zip"
FINAL_ZIP="$ROOT/build/${SCHEME}-notarized.zip"

NOTARY_PROFILE="${NOTARY_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_PASSWORD="${APPLE_PASSWORD:-}"

if [[ -z "$NOTARY_PROFILE" ]]; then
  if [[ -z "$APPLE_ID" ]]; then
    read -r -p "Apple ID: " APPLE_ID
  fi
  if [[ -z "$APPLE_PASSWORD" ]]; then
    read -r -s -p "App-specific password: " APPLE_PASSWORD
    echo
  fi
fi

rm -rf "$ROOT/build"
mkdir -p "$ROOT/build" "$EXPORT_PATH"

echo "==> Archive"
xcodebuild clean archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH"

echo "==> Export (Developer ID)"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_PATH"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Exported app not found: $APP_PATH"
  exit 1
fi

echo "==> Create ZIP for notarization"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Notarize"
if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
else
  xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "B7VP34NYD2" \
    --password "$APPLE_PASSWORD" \
    --wait
fi

echo "==> Staple"
xcrun stapler staple "$APP_PATH"

echo "==> Final ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP"

echo "Done: $FINAL_ZIP"
