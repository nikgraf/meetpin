# Meetpin Plan

## Current state

- pnpm workspace with the Expo Router app in `apps/mobile`
- Shared lint, format, test, and CI config now live at the workspace root
- Uniwind is wired through `apps/mobile/src/global.css` and `apps/mobile/metro.config.js`
- Basic unit tests, Maestro smoke scaffolding, and a GitHub Actions workflow are now in place

## Recommended order

1. Complete the pnpm workspace/monorepo foundation first
2. Add ESLint and Prettier so formatting and linting are stable before larger refactors
3. Add unit testing for fast feedback on components and hooks
4. Switch styling to Uniwind following the current official docs once the project structure is settled
5. Add Maestro after the main user flows are stable enough to automate
6. Add GitHub Actions after local scripts are reliable
7. Run web and iOS verification passes and fix whatever still breaks

## Work items

- [x] Complete the pnpm workspace monorepo migration
  - Confirm the target structure. The likely end state is `apps/mobile` (or `apps/app`) plus optional shared packages such as `packages/ui`, `packages/config`, and `packages/types`.
  - Move the current Expo app out of the repo root if the goal is a real monorepo, otherwise rename this task to "finish pnpm workspace setup" to match the actual scope.
  - Add root-level scripts for common tasks such as `dev`, `lint`, `test`, and `typecheck`, and wire them through `pnpm --filter`.
  - Update path aliases, TypeScript config, Expo entry points, and asset paths after the move.
  - Verify `pnpm install` works from the root and the Expo app still starts from the workspace.
  - Done when the app runs from the workspace root and there is a clear place for future shared packages.

- [x] Setup ESLint and Prettier for linting and formatting
  - Decide whether to extend Expo's ESLint defaults or switch to a custom flat config at the workspace root.
  - Add ESLint config for TypeScript, React, React Hooks, and React Native/Expo-specific rules that fit the codebase.
  - Add Prettier config plus any small set of plugins only if they are clearly needed.
  - Decide how import ordering should work and whether it should be enforced by ESLint, Prettier, or left out initially to keep the setup simple.
  - Add scripts such as `lint`, `lint:fix`, `format`, and `format:check`.
  - Run ESLint and Prettier against the current `src`, `scripts`, and config files and clean up any violations.
  - Done when ESLint and Prettier can run in CI without noisy false positives and developers have one obvious command for linting plus one for formatting.

- [x] Setup unit testing
  - Choose the stack. For this repo, `jest-expo` plus React Native Testing Library is the most direct fit unless there is a reason to use Vitest for non-UI packages later.
  - Add a shared test config, test script, and basic setup file for matchers and mocks.
  - Start with small, stable tests for `src/hooks`, `src/components`, and any new pure utility modules.
  - Avoid snapshot-heavy coverage for now; prefer behavior-focused tests around rendering, theming, and interaction.
  - Add at least one example test for a themed component and one for a simple hook to prove the setup works.
  - Done when `pnpm test` passes locally and the structure supports adding tests without extra boilerplate.

- [x] Switch styling to Uniwind using the current setup from `https://docs.uniwind.dev/`
  - Follow the official Quickstart and Metro config docs rather than older NativeWind-style setup guides.
  - Upgrade or confirm compatibility with Tailwind CSS v4, since Uniwind requires Tailwind 4.
  - Keep `global.css` as the CSS entry file and ensure it includes both required imports: Tailwind plus Uniwind.
  - Import `global.css` from the app entry component rather than a root registration file so style edits keep hot reload behavior.
  - Add `metro.config.js` and wrap Expo's Metro config with `withUniwindConfig(...)`, making it the outermost Metro wrapper.
  - Set `cssEntryFile` correctly, and choose a `dtsFile` location that is automatically included by TypeScript or explicitly added to `tsconfig.json`.
  - Because this repo is moving toward a pnpm monorepo and already keeps routes in `src/app`, use the official `@source` approach if class scanning needs to include sibling folders or shared packages outside the CSS entry directory.
  - Decide the migration boundary: full replacement of `StyleSheet` usage or gradual adoption for new screens first.
  - Validate the setup on iOS and web, especially around dark mode, theme variables, platform-specific classes, and any existing `src/global.css` usage.
  - Convert one or two representative components first instead of rewriting the whole app immediately.
  - Done when one real screen/component path uses Uniwind successfully on iOS and web, Metro type generation works, and the team has a clear migration pattern aligned with the official docs.

- [x] Setup Maestro for E2E testing
  - Pick the initial smoke flows instead of trying to cover the whole app. Right now that likely means app launch, tab navigation, and at least one core happy path once product screens exist.
  - Add a `maestro` folder with flows, test data notes, and a README for how to run them.
  - Create stable selectors or accessibility labels in the UI where needed; do not rely on brittle text-only selectors if the copy will change often.
  - Add scripts for running flows locally against iOS simulator and, if useful later, Android.
  - Keep the first iteration as a smoke suite that can run reliably in CI rather than a large, flaky suite.
  - Current status: the Expo Go simulator smoke flow passed locally, and the standalone-app flow remains ready for use once a real iOS app identifier exists.
  - Done when at least one end-to-end flow runs consistently from a clean bootstrapped environment.

- [x] Setup CI/CD using GitHub Actions on pushes to `main` and selected branches
  - Clarify the branch strategy. "a branch (not a PR)" should be turned into an explicit pattern such as `develop`, `release/*`, or all branches.
  - Add a workflow that installs dependencies with pnpm, restores caches, and runs the baseline checks: typecheck, lint, unit tests, and any lightweight build verification.
  - Keep E2E optional at first unless runtime and simulator setup are acceptable for every push.
  - If deployments are in scope later, separate CI from CD so build verification and release automation do not block each other.
  - Add status output that makes failures actionable instead of burying them in one large script.
  - Done when a push to `main` and the chosen non-PR branch pattern runs the expected checks with acceptable runtime.

- [x] Run the web and iOS builds to verify everything is working and fix issues
  - Define the exact verification commands after the workspace migration so they reflect the final project layout.
  - For web, confirm the app starts and renders without routing, asset, or CSS regressions.
  - For iOS, confirm the app boots in the simulator and that navigation, safe areas, fonts, and splash behavior still work.
  - Capture any build or runtime issues in this file as follow-up tasks rather than fixing them informally and forgetting them.
  - Current status: `pnpm build:web` succeeds, and Expo launched on the booted iOS simulator and completed the iOS JS bundle successfully.
  - Done when both targets launch successfully from a fresh install and there are no known blocking errors.

## Cross-cutting notes

- Prefer root-level shared config for ESLint, Prettier, TypeScript, and tests once the monorepo shape is in place.
- Keep the first pass small and reliable. The goal is a stable baseline, not maximum tooling coverage on day one.
- After each major setup step, rerun the app on web and iOS so regressions are caught close to the change that caused them.
