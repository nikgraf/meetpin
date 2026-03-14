#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="${LOG_FILE:-expo-ios.log}"

cleanup() {
  if [[ -n "${EXPO_PID:-}" ]] && kill -0 "${EXPO_PID}" 2>/dev/null; then
    kill "${EXPO_PID}" || true
    wait "${EXPO_PID}" || true
  fi
}

trap cleanup EXIT

CI=1 pnpm --filter @meetpin/mobile exec expo start --ios >"${LOG_FILE}" 2>&1 &
EXPO_PID=$!

for _ in $(seq 1 36); do
  if grep -q 'Opening exp://' "${LOG_FILE}"; then
    break
  fi

  if ! kill -0 "${EXPO_PID}" 2>/dev/null; then
    cat "${LOG_FILE}"
    exit 1
  fi

  sleep 5
done

if ! grep -q 'Opening exp://' "${LOG_FILE}"; then
  cat "${LOG_FILE}"
  exit 1
fi

MAESTRO_CLI_NO_ANALYTICS=1 \
MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true \
maestro --platform ios test --debug-output ./.maestro-debug maestro/ios-expo-go-smoke.yaml
