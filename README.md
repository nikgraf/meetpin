# Meetpin Workspace

This repository is a pnpm workspace with the Expo app in `apps/mobile`.

## Commands

```bash
pnpm install
pnpm dev
pnpm ios
pnpm web
pnpm lint
pnpm test
pnpm e2e:playwright
pnpm verify
pnpm build:web
```

## Environment

The Expo app now uses a dynamic config in [apps/mobile/app.config.ts](apps/mobile/app.config.ts).

Copy [apps/mobile/.env.example](apps/mobile/.env.example) to `apps/mobile/.env` and adjust values as needed.

The key starter variables are:

- `APP_VARIANT`: `development`, `preview`, or `production`
- `EXPO_PUBLIC_API_URL`: API base URL exposed to the app
- `IOS_BUNDLE_IDENTIFIER` / `ANDROID_APPLICATION_ID`: optional native identifier overrides
- `EAS_PROJECT_ID`: optional Expo project ID once the project is linked to EAS

Without overrides, production keeps the current identifiers and dev/preview derive suffixes automatically.

## EAS Build Profiles

Build profiles are defined in [eas.json](eas.json):

- `development`: internal development client
- `preview`: internal distribution build
- `production`: production build with auto-increment enabled

Examples:

```bash
pnpm dlx eas-cli build --platform ios --profile preview
pnpm dlx eas-cli build --platform android --profile production
```

Note: the repository is not linked to an Expo project yet unless you set
`EAS_PROJECT_ID` or run `eas init` from [apps/mobile](apps/mobile).

## Structure

- `apps/mobile`: Expo Router application
- `maestro`: smoke E2E flows and notes
- `packages`: reserved for future shared packages

## Notes

- Shared lint, format, test, and CI config live at the workspace root.
- Uniwind is wired through `apps/mobile/src/global.css` and `apps/mobile/metro.config.js`.
