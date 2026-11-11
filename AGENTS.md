# AGENTS.md

Instructions for agents working in this repository. RFC 2119 keywords apply.

## Package Scope

- This is a Swift package for a reusable SwiftUI welcome experience.
- The supported product surfaces are iOS 26+ and macOS 26+.
- watchOS is out of scope unless the user explicitly asks for watchOS work. Do not widen implementation, tests, or compatibility policy for watchOS by default.
- Keep the library presentational and reusable. App-specific policy belongs in the consuming app unless the public API is explicitly changed.

## SwiftUI Standards

- Use pure SwiftUI for product UI. Avoid UIKit/AppKit bridging unless there is no native SwiftUI API and the bridge is small, isolated, and explained.
- Prefer modern Swift and SwiftUI idioms for the declared platform minimums. Do not use deprecated APIs such as `NavigationView`, `navigationBarItems`, `foregroundColor`, old `alert` overloads, or `animation(_:)` without `value:`.
- Use `Button` for tappable controls. Use gestures only when the gesture semantics matter.
- Keep view state local and private. Use `@Binding` only when this package intentionally lets the caller own and mutate state.
- Preserve accessibility in every UI change: VoiceOver labels/grouping, Dynamic Type, reduced motion, sufficient contrast, keyboard/focus behavior where relevant, and light/dark mode.
- Design layouts to survive small and large iPhones, iPad-style widths, portrait and landscape, and resizable macOS windows. Avoid brittle fixed sizes except for icons, minimums, or platform-specific constants.
- Use system materials, typography, controls, and symbols in ways that feel native on iOS 26+ and macOS 26+. Do not add custom visual systems unless the user asks for one.
- Keep public API names, defaults, and initializer behavior stable unless the requested change explicitly requires a breaking change.

## GreetKit Rules

- `GreetView` should remain a reusable SwiftUI view driven by `GreetContent`.
- The consuming app owns loading, errors, completion, dismissal, and persistence. Keep this package presentational unless the requested change explicitly expands scope.
- `isLoading` and `errorMessage` bindings are part of the public behavior and must stay predictable under repeated taps, alert dismissal, and optional skip states.
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

- Use Sosumi for current Apple documentation when SwiftUI, platform APIs, or Human Interface Guidelines details matter.
- Use Context7 for current, version-specific documentation for non-Apple libraries.
- Keep README examples aligned with public APIs whenever API behavior changes.
- Record every public API or behavior change under `## [Unreleased]` in `CHANGELOG.md`.
- Use semantic commit messages when committing changes, such as `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, or `chore:`.
