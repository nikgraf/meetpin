#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="${LOG_FILE:-expo-ios.log}"
XCODE_BUILD_DIR="${XCODE_BUILD_DIR:-$PWD/.xcode-build}"
IOS_PROJECT_DIR="apps/mobile/ios"
IOS_SCHEME="${IOS_SCHEME:-meetpin}"
APP_NAME="${APP_NAME:-meetpin}"

if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "DEVICE_ID must be set before running the iOS Maestro CI script." >&2
  exit 1
fi

APP_ID="${APP_ID:-$(python3 - <<'PY'
import json
from pathlib import Path

config = json.loads(Path('apps/mobile/app.json').read_text())
print(config['expo']['ios']['bundleIdentifier'])
PY
)}"

if [[ -z "${APP_ID}" ]]; then
  echo "APP_ID could not be determined from apps/mobile/app.json." >&2
  exit 1
fi

echo "Building ${APP_ID} for simulator ${DEVICE_ID}"

ruby <<'RUBY'
podspec_path = 'node_modules/expo-modules-core/ExpoModulesCore.podspec'
podspec = File.read(podspec_path)

podspec.sub!("s.swift_version  = '6.0'", "s.swift_version  = '5.10'")

unless podspec.include?("'SWIFT_STRICT_CONCURRENCY' => 'minimal'")
  podspec.sub!(
    "'SWIFT_COMPILATION_MODE' => 'wholemodule',\n",
    "'SWIFT_COMPILATION_MODE' => 'wholemodule',\n    'SWIFT_STRICT_CONCURRENCY' => 'minimal',\n"
  )
end

File.write(podspec_path, podspec)
RUBY

ruby <<'RUBY'
replacements = {
  'node_modules/expo-modules-core/ios/Core/Views/SwiftUI/SwiftUIHostingView.swift' => {
    '  public final class HostingView<Props: ViewProps, ContentView: View<Props>>: ExpoView, @MainActor AnyExpoSwiftUIHostingView {' =>
      "  @MainActor\n  public final class HostingView<Props: ViewProps, ContentView: View<Props>>: ExpoView, AnyExpoSwiftUIHostingView {"
  },
  'node_modules/expo-modules-core/ios/Core/Views/SwiftUI/SwiftUIVirtualView.swift' => {
    'extension ExpoSwiftUI.SwiftUIVirtualView: @MainActor ExpoSwiftUI.ViewWrapper {' =>
      "@MainActor\nextension ExpoSwiftUI.SwiftUIVirtualView: ExpoSwiftUI.ViewWrapper {"
  },
  'node_modules/expo-modules-core/ios/Core/Views/ViewDefinition.swift' => {
    'extension UIView: @MainActor AnyArgument {' =>
      "@MainActor\nextension UIView: AnyArgument {"
  }
}

replacements.each do |path, file_replacements|
  contents = File.read(path)
  file_replacements.each do |before, after|
    contents.sub!(before, after)
  end
  File.write(path, contents)
end
RUBY

pnpm --filter @meetpin/mobile exec expo prebuild --platform ios --no-install
(
  cd "${IOS_PROJECT_DIR}"
  pod install
)

echo "Building ${APP_NAME}.app with xcodebuild"
xcodebuild \
  -workspace "${IOS_PROJECT_DIR}/${IOS_SCHEME}.xcworkspace" \
  -scheme "${IOS_SCHEME}" \
  -configuration Release \
  -destination "id=${DEVICE_ID}" \
  -derivedDataPath "${XCODE_BUILD_DIR}" \
  build | tee "${LOG_FILE}"

APP_PATH="${XCODE_BUILD_DIR}/Build/Products/Release-iphonesimulator/${APP_NAME}.app"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Built app not found at ${APP_PATH}" >&2
  exit 1
fi

echo "Installing ${APP_PATH}"
xcrun simctl install "${DEVICE_ID}" "${APP_PATH}"
xcrun simctl launch "${DEVICE_ID}" "${APP_ID}" || true
sleep 5

APP_ID="${APP_ID}" \
MAESTRO_CLI_NO_ANALYTICS=1 \
MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true \
maestro --platform ios test --debug-output ./.maestro-debug maestro/ios-smoke.yaml
