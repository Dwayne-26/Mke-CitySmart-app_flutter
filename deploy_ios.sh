#!/bin/bash

# ============================
# FLUTTER iOS DEPLOY SCRIPT
# ============================
# This script:
#  1. Increments iOS build number (CFBundleVersion)
#  2. Builds a Flutter iOS .ipa (release)
#  3. Uploads it to App Store Connect using Fastlane
#
# Requirements: Xcode, Fastlane, Flutter, Apple Developer account

set -e

# --------- CONFIG: EDIT THESE ---------
APP_NAME="mkecitysmart"
BUNDLE_ID="com.mkecitysmart.app"
APPLE_ID="mkeparkapp@gmail.com"     # your Apple ID (or App Store Connect email)
TEAM_ID="J8U8FW3PA8"           # Apple Developer Team ID
ITC_TEAM_ID="J8U8FW3PA8"         # App Store Connect Team ID (iTunes Team ID)
IPA_PATH="build/ios/ipa/Runner.ipa"
INFO_PLIST="ios/Runner/Info.plist"
# --------------------------------------

echo "📱 Deploying $APP_NAME ($BUNDLE_ID) to the App Store"

# ----------------------------
# Step 0: Increment build number
# ----------------------------
echo "🔢 Incrementing iOS build number (CFBundleVersion)..."

if [ ! -f "$INFO_PLIST" ]; then
  echo "❌ Info.plist not found at $INFO_PLIST"
  exit 1
fi

# Get current build number (defaults to 0 if missing)
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "0")

# If it's not an integer, reset to 0
if ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Current CFBundleVersion ('$CURRENT_BUILD') is not an integer. Resetting to 0."
  CURRENT_BUILD=0
fi

NEXT_BUILD=$((CURRENT_BUILD + 1))

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEXT_BUILD" "$INFO_PLIST"

echo "✅ Build number updated: $CURRENT_BUILD → $NEXT_BUILD"

# ----------------------------
# Step 1: Ensure Dependencies
# ----------------------------
echo "🔧 Checking for required tools..."

if ! command -v fastlane &> /dev/null; then
  echo "⚠️ Fastlane not found. Installing..."
  sudo gem install fastlane -NV
fi

if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found. Please install Flutter SDK first."
  exit 1
fi

# ----------------------------
# Step 2: Clean & Build IPA
# ----------------------------
echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Building iOS IPA (release)..."
flutter build ipa --release

if [ ! -f "$IPA_PATH" ]; then
  echo "❌ Build failed: IPA not found at $IPA_PATH"
  exit 1
fi

# ----------------------------
# Step 3: Prepare Fastlane Config
# ----------------------------
cd ios

mkdir -p fastlane

cat > fastlane/Appfile <<EOF_APP
app_identifier("$BUNDLE_ID")
apple_id("$APPLE_ID")
itc_team_id("$ITC_TEAM_ID")
team_id("$TEAM_ID")

# Optional: If you have an API key, uncomment and fill in:
# api_key({
#   key_id: "XXXXXX",
#   issuer_id: "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY",
#   key_filepath: "./fastlane/AuthKey_XXXXXX.p8"
# })
EOF_APP

cat > fastlane/Fastfile <<'EOF_FAST'
default_platform(:ios)

platform :ios do
  desc "Deploy Flutter iOS app to the App Store"
  lane :release do
    ipa_path = "../build/ios/ipa/Runner.ipa"

    # Ensure the IPA exists
    unless File.exist?(ipa_path)
      sh "cd .. && flutter build ipa --release"
    end

    upload_to_app_store(
      ipa: ipa_path,
      skip_metadata: true,
      skip_screenshots: true,
      submit_for_review: false,
      automatic_release: false
    )
  end
end
EOF_FAST

# ----------------------------
# Step 4: Upload via Fastlane
# ----------------------------
echo "🚀 Uploading build to App Store Connect..."
fastlane release

cd ..

# ----------------------------
# Step 5: Done!
# ----------------------------
echo "✅ Deployment complete!"
echo "   Build number: $NEXT_BUILD"
echo "   Check App Store Connect → https://appstoreconnect.apple.com/apps"
