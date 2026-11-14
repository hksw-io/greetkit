# AGENTS.md

Instructions for agents working in this repository.

## Package Scope

- This is a Swift package for a reusable SwiftUI welcome experience.
- The supported product surfaces are iOS 26+ and macOS 26+.
- watchOS is out of scope unless the user explicitly asks for watchOS work. Do not widen implementation, tests, or compatibility policy for watchOS by default.
- Keep the library presentational and reusable. App-specific policy belongs in the consuming app unless the public API is explicitly changed.

## SwiftUI Standards

- Use pure SwiftUI for product UI. Avoid UIKit/AppKit bridging unless there is no native SwiftUI API and the bridge is small, isolated, and explained.
- Preserve accessibility in every UI change: VoiceOver labels/grouping, Dynamic Type, reduced motion, sufficient contrast, keyboard/focus behavior where relevant, and light/dark mode.
- Keep public API names, defaults, and initializer behavior stable unless the requested change explicitly requires a breaking change.

## GreetKit Rules

- `GreetView` should remain a reusable SwiftUI view driven by `GreetContent`.
- The consuming app owns loading, errors, completion, dismissal, and persistence. Keep this package presentational unless the requested change explicitly expands scope.
- The `isLoading` flag and the `errorMessage` binding are part of the public behavior and must stay predictable under repeated taps, alert dismissal, and optional skip states.
- Feature rows must keep stable identity and work with optional icons, labels, subtitles, skip buttons, and long localized text.
- Primary and skip actions remain caller-controlled through `onPrimary` and `onSkip`.

## Testing and Verification

- Add or update Swift Testing coverage for every feature, behavior change, or bug fix.
- Cover public API behavior, protocol defaults, optional content combinations, callbacks, binding behavior, loading/error states, and regression cases.
- UI-facing changes need automated construction/smoke coverage and manual or preview verification across varied screen sizes, orientations, and devices/windows.
- Run `swift test` before calling work complete. If the change is UI-heavy, also exercise Xcode previews or an equivalent local host app.
- `swift test` builds for macOS only. When a change touches platform-conditional code, also run `xcodebuild -scheme GreetKit -destination 'generic/platform=iOS' build`.
- Keep the pure helpers (layout, mask, and motion math) free of SwiftUI view types so they stay unit-testable without a hosted view.
- Run `git diff --check` before finalizing.
- CI (`.github/workflows/ci.yml`) runs the macOS build, the tests, and the iOS build. Keep it green.

## Documentation and Dependencies

- Keep README examples aligned with public APIs whenever API behavior changes.
- Record every public API or behavior change under `## [Unreleased]` in `CHANGELOG.md`.
- A minor release may contain a breaking change, marked **Breaking** in `CHANGELOG.md`, so consumers pin exact versions.
- Use semantic commit messages when committing changes, such as `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, or `chore:`.
