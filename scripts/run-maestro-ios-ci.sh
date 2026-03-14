#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="${LOG_FILE:-expo-ios.log}"

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

pnpm --filter @meetpin/mobile exec expo prebuild --platform ios --no-install
(
  cd apps/mobile/ios
  pod install
)

pnpm --filter @meetpin/mobile exec expo run:ios \
  --configuration Release \
  --no-install \
  --no-bundler \
  --device "${DEVICE_ID}" | tee "${LOG_FILE}"

xcrun simctl launch "${DEVICE_ID}" "${APP_ID}" || true
sleep 5

APP_ID="${APP_ID}" \
MAESTRO_CLI_NO_ANALYTICS=1 \
MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true \
maestro --platform ios test --debug-output ./.maestro-debug maestro/ios-smoke.yaml
