#!/usr/bin/env bash

# Script to upgrade the active Xcode to a 16.x release entirely from the CLI.
# It installs the robotsandpencils "xcodes" helper, downloads the requested
# Xcode build, sets it as the selected toolchain, and walks through the initial
# setup commands Apple requires for new installations.

set -euo pipefail

TARGET_VERSION="16.1"

echo "🔧 Installing the xcodes CLI helper via Homebrew (if missing)..."
brew list xcodes >/dev/null 2>&1 || brew install robotsandpencils/made/xcodes

echo "📥 Installing Xcode ${TARGET_VERSION} (Apple ID auth required on first run)..."
sudo xcodes install "${TARGET_VERSION}" --select

echo "✅ Xcode ${TARGET_VERSION} set as the active developer directory via xcode-select."

echo "📄 Accepting the Xcode license..."
sudo xcodebuild -license accept

echo "⚙️ Running first-launch tasks..."
sudo xcodebuild -runFirstLaunch

echo "🔎 Installed toolchain details:"
xcodebuild -version
xcodebuild -showsdks | grep iphoneos || true

cat <<"NEXT_STEPS"

Next steps:
  1. Run `flutter doctor -v` to ensure the new toolchain is detected.
  2. Clean and rebuild your iOS artifacts (e.g., `flutter clean && flutter build ipa --release`).

NEXT_STEPS
