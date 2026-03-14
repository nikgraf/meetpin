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
pnpm verify
pnpm build:web
```

## Structure

- `apps/mobile`: Expo Router application
- `maestro`: smoke E2E flows and notes
- `packages`: reserved for future shared packages

## Notes

- Shared lint, format, test, and CI config live at the workspace root.
- Uniwind is wired through `apps/mobile/src/global.css` and `apps/mobile/metro.config.js`.
