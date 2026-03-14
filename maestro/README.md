# Maestro Smoke Tests

These flows cover the first stable navigation smoke path for iOS.

## Prerequisites

- Install Maestro CLI: https://docs.maestro.dev/getting-started/installing-maestro
- Boot an iOS simulator
- Launch the app in a simulator build or development build

## Usage

For a standalone iOS app build, set the installed app identifier and run:

```bash
export APP_ID=com.example.meetpin
pnpm maestro:ios
```

If the app identifier changes later, update the `APP_ID` environment variable instead of editing the flow.

For Expo Go on the booted simulator, start the Expo app first and then run:

```bash
pnpm --filter @meetpin/mobile exec expo start --ios
maestro --platform ios test maestro/ios-expo-go-smoke.yaml
```
