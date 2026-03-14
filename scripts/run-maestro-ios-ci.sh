#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="${LOG_FILE:-expo-ios.log}"
OPEN_URL_PATTERN='exp://[^[:space:]]+'

cleanup() {
  if [[ -n "${EXPO_PID:-}" ]] && kill -0 "${EXPO_PID}" 2>/dev/null; then
    kill "${EXPO_PID}" || true

    local remaining=10
    while (( remaining > 0 )) && kill -0 "${EXPO_PID}" 2>/dev/null; do
      sleep 1
      remaining=$((remaining - 1))
    done

    if kill -0 "${EXPO_PID}" 2>/dev/null; then
      kill -9 "${EXPO_PID}" || true
    fi

    wait "${EXPO_PID}" || true
  fi
}

trap cleanup EXIT

CI=1 pnpm --filter @meetpin/mobile exec expo start --ios --tunnel >"${LOG_FILE}" 2>&1 &
EXPO_PID=$!

wait_for_log_pattern() {
  local pattern="$1"
  local timeout_seconds="$2"
  local elapsed=0

  while (( elapsed < timeout_seconds )); do
    if grep -Eq "${pattern}" "${LOG_FILE}"; then
      return 0
    fi

    if ! kill -0 "${EXPO_PID}" 2>/dev/null; then
      cat "${LOG_FILE}"
      exit 1
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  cat "${LOG_FILE}"
  return 1
}

wait_for_log_pattern "${OPEN_URL_PATTERN}" 180
EXPO_URL=$(grep -Eo "${OPEN_URL_PATTERN}" "${LOG_FILE}" | tail -n 1)

if [[ -z "${EXPO_URL}" ]]; then
  cat "${LOG_FILE}"
  exit 1
fi

echo "Using Expo URL ${EXPO_URL}"

sleep 10

MAESTRO_CLI_NO_ANALYTICS=1 \
MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true \
maestro --platform ios test --debug-output ./.maestro-debug maestro/ios-expo-go-smoke.yaml
