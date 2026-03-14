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

ruby <<'RUBY'
replacements = {
  'node_modules/expo-router/ios/Toolbar/RouterToolbarHostView.swift' => {
    <<~'BEFORE' => <<~'AFTER'
              if #available(iOS 26.0, *) {
                if let hidesSharedBackground = menu.hidesSharedBackground {
                  item.hidesSharedBackground = hidesSharedBackground
                }
                if let sharesBackground = menu.sharesBackground {
                  item.sharesBackground = sharesBackground
                }
              }
    BEFORE
    AFTER
  },
  'node_modules/expo-router/ios/Toolbar/RouterToolbarItemView.swift' => {
    <<~'BEFORE' => <<~'AFTER',
    } else if type == .searchBar {
      guard #available(iOS 26.0, *), let controller = self.host?.findViewController() else {
        // Check for iOS 26, should already be guarded by the JS side, so this warning will only fire if controller is nil
        logger?.warn(
          "[expo-router] navigationItem.searchBarPlacementBarButtonItem not available. This is most likely a bug in expo-router."
        )
        currentBarButtonItem = nil
        return
      }
      guard let navController = controller.navigationController else {
        currentBarButtonItem = nil
        return
      }
      guard navController.isNavigationBarHidden == false else {
        logger?.warn(
          "[expo-router] Toolbar.SearchBarPreferredSlot should only be used when stack header is shown."
        )
        currentBarButtonItem = nil
        return
      }

      item = controller.navigationItem.searchBarPlacementBarButtonItem
    BEFORE
    } else if type == .searchBar {
      logger?.warn(
        "[expo-router] Toolbar.SearchBarPreferredSlot requires a newer iOS SDK than is available in this CI build."
      )
      currentBarButtonItem = nil
      return
    AFTER
    <<~'BEFORE' => <<~'AFTER',
    if #available(iOS 26.0, *) {
      item.hidesSharedBackground = hidesSharedBackground
      item.sharesBackground = sharesBackground
    }
    BEFORE
    AFTER
    <<~'BEFORE' => <<~'AFTER'
    if #available(iOS 26.0, *) {
      if let badgeConfig = badgeConfiguration {
        var badge = UIBarButtonItem.Badge.indicator()
        if let value = badgeConfig.value {
          badge = .string(value)
        }
        if let backgroundColor = badgeConfig.backgroundColor {
          badge.backgroundColor = backgroundColor
        }
        if let foregroundColor = badgeConfig.color {
          badge.foregroundColor = foregroundColor
        }
        if badgeConfig.fontFamily != nil || badgeConfig.fontSize != nil
          || badgeConfig.fontWeight != nil {
          let font = RouterFontUtils.convertTitleStyleToFont(
            TitleStyle(
              fontFamily: badgeConfig.fontFamily,
              fontSize: badgeConfig.fontSize,
              fontWeight: badgeConfig.fontWeight
            ))
          badge.font = font
        }
        item.badge = badge
      } else {
        item.badge = nil
      }
    }
    BEFORE
    if badgeConfiguration != nil {
      logger?.warn(
        "[expo-router] Toolbar badges require a newer iOS SDK than is available in this CI build."
      )
    }
    AFTER
  },
  'node_modules/expo-router/ios/Toolbar/RouterToolbarModule.swift' => {
    <<~'BEFORE' => <<~'AFTER'
    case .prominent:
      if #available(iOS 26.0, *) {
        return .prominent
      } else {
        return .done
      }
    BEFORE
    case .prominent:
      return .done
    AFTER
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
