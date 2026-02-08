#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/threemonthcal/threemonthcal.xcodeproj"
SCHEME="threemonthcal"
CONFIGURATION="Release"
ARCHIVE_PATH="$ROOT/build/${SCHEME}.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_OPTIONS="$ROOT/scripts/ExportOptions.plist"
EXPORT_OPTIONS_TMP="$ROOT/build/ExportOptions.plist"
APP_PATH="$EXPORT_PATH/${SCHEME}.app"
ZIP_PATH="$ROOT/build/${SCHEME}.zip"
FINAL_ZIP="$ROOT/build/${SCHEME}-notarized.zip"

TEAM_ID="${TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-}"

LOCAL_CONFIG="$ROOT/threemonthcal/Config/Local.xcconfig"
if [[ -z "$TEAM_ID" && -f "$LOCAL_CONFIG" ]]; then
  TEAM_ID="$(awk -F= '/^TEAM_ID[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2}' "$LOCAL_CONFIG")"
fi
if [[ -z "$BUNDLE_ID" && -f "$LOCAL_CONFIG" ]]; then
  BUNDLE_ID="$(awk -F= '/^BUNDLE_ID[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2}' "$LOCAL_CONFIG")"
fi

if [[ -z "$TEAM_ID" ]]; then
  echo "TEAM_ID is not set. Set TEAM_ID env or update $LOCAL_CONFIG."
  exit 1
fi

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
cp "$EXPORT_OPTIONS" "$EXPORT_OPTIONS_TMP"
/usr/libexec/PlistBuddy -c "Set :teamID $TEAM_ID" "$EXPORT_OPTIONS_TMP"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_TMP" \
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
    --team-id "$TEAM_ID" \
    --password "$APPLE_PASSWORD" \
    --wait
fi

echo "==> Staple"
xcrun stapler staple "$APP_PATH"

echo "==> Final ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP"

echo "Done: $FINAL_ZIP"
