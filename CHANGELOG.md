# Changelog

All notable changes to GreetKit are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Back navigation and Command-[ in setup routes, with consumer-localized copy and VoiceOver focus restoration.

### Fixed

- Route actions share the loading state, and pending or failed completion retains the final step for retry.

## [3.0.0] - 2026-08-09

An over-engineering audit, applied. Roughly a thousand lines leave the package and no feature does:
every cut is either a second way to do something the package already did, or a helper standing
between a call site and an API that already handled the case.

### Removed

- **Breaking.** `GreetStyle` keeps `tint` and loses its seven other colour roles — `titleColor`,
  `subtitleColor`, `featureIconColor`, `featureTitleColor`, `featureDescriptionColor`,
  `primaryButtonForegroundColor`, and `secondaryButtonColor`. All seven defaulted to `nil` meaning
  "use the system treatment", so each one existed to let an app replace a system label colour with a
  hand-picked one. Text now uses the system label hierarchy, and the primary button its own
  prominent glass treatment. `featureIconColor` was doubly redundant: it fell back to `tint`, which
  the view already publishes to the environment.
- **Breaking.** `GreetGradientPalette` and the `palette:` parameter on `.softGradient` and
  `.animatedGradient`. It was a third way to recolour one background, on top of `brand:` and
  `.custom`, and the only one wide enough — eight colours over two schemes — to compose a field the
  gradient tuning was never balanced against. Pass `brand:`, or draw it yourself with `.custom`.
- **Breaking.** `.linearGradient(colors:startPoint:endPoint:)`. It applied no treatment of its own,
  so it is `.custom { _ in LinearGradient(...) }` with the SwiftUI type the caller already knows.
- **Breaking.** The `primaryDestination:` initializer. A single follow-up step is a chain of one:
  `primaryRoutes: [GreetPrimaryRoute(id: "setup")]` with `primaryRouteDestination:`, where the
  button reads Done rather than Next. It was a parallel implementation of the route chain,
  unreachable at the same time as one, with its own container, its own state flag, its own
  precedence rule, and four tests covering nothing but which of the two paths won.

### Changed

- `GreetGradientMotion.strength` now controls motion alone. It used to drive three visual scales as
  well, brightening the base tint and blobs and tightening the blur as the gradient sped up — so
  choosing `.subtle` because the drift was distracting also gave you a paler sheet. Reduce Motion
  and Reduce Transparency damp those two things separately, and so should this. `.animatedGradient()`
  renders exactly as before; `.subtle` and `.expressive` now differ from it in travel and speed only.

### Internal

- `LayoutMetrics.horizontalPadding(for:compact:regular:breakpoint:)` becomes
  `Tokens.Layout.isCompact(width:)`; three of its four parameters existed only so tests could pass
  literals to a one-line ternary.
- `GreetKeyboardPolicy` is inlined. An enum, a static function, and a four-case test file wrapped
  `a && b`. Escape behaviour is unchanged.
- The two copies of `damped(for:)` become one mechanism. `GreetGradientAccessibility` is now
  `GreetGradientDamping`: its two Bools collapse to the one flag they were `||`-ed into, and its two
  loose constants become the `tint(_:)` and `veil(_:)` operations that consumed them.
- `greetTint(_:)` and `greetCancelShortcut(_:)` are gone — `tint(_: Color?)` and
  `keyboardShortcut(_: KeyboardShortcut?)` already accept the optional.
- The repeated macOS sheet frame becomes `greetSheetSizing()`. `GreetFeatureList` is inlined.
  `GreetBackgroundView` stays, as a render boundary for the animating `Canvas`, but reads its own
  accessibility environment instead of taking four forwarded properties.
- Nineteen of twenty-five view tests had no expectation — their bodies were `_ = GreetView(...)`,
  which the compiler proves. One broad smoke test covers the surface instead. Six previews become
  two: the interactive one, and one applying every layout stress at once.

## [2.0.1] - 2026-07-25

### Changed

- The brand-derived gradient palette is calmer and reads as one colour. `GreetGradientPalette.brand(_:)`
  used to pair any brand colour with fixed `.cyan` and `.mint` (light) or `.purple` and `.cyan`
  (dark), so the field was three unrelated hues; the supporting tones are now the brand washed
  toward the platform surface. Since that surface is light in light mode and dark in dark mode, the
  same wash lifts the palette in one and deepens it in the other.
- `.animatedGradient` is substantially softer. Light mode had carried the *highest* base tint of
  either scheme (0.38 against dark's 0.26) under almost no veil (0.04, where `.softGradient` reaches
  0.78) — the veil is the surface colour painted back over the field, so with it near zero nothing
  tempered the colour. Veils are up and tints, blob opacities, and blur are retuned in both schemes.
- Not source-breaking, but every caller using a brand-derived gradient will look different.
  `.softGradient` shares the same palette factory, so its hues change too; its own intensity tuning
  is untouched. Explicit `palette:` overrides are unaffected.
- The title, subtitle, and feature rows are selectable, which Mac users expect of a window they may
  want to copy out of.

### Fixed

- The primary button sat against the bottom edge of the sheet. `footerBottomPadding` was zero, which
  the overview hid because the skip button sits below the primary one — but a route page has no skip
  button, so nothing held it off the edge.

Ported from ReleaseKit, which had the same gradient defect. Both packages ship in the same app, so
the values match.

## [2.0.0] - 2026-07-25

Makes the package feel native on each platform rather than presenting one iOS design on both, and
adopts the iOS 26 / macOS 26 control layer in place of three hand-rolled equivalents.

### Added

- **Breaking.** `GreetBackgroundContext` gains `reduceTransparency` and `colorSchemeContrast`, both
  defaulted, so custom backgrounds can react to them. The built-in gradients now do: under either
  setting the color wash is damped and more of the opaque base shows, so foreground contrast stops
  depending on where a gradient blob lands.
- Keyboard support. Return triggers the primary action — including Next and Done inside a route
  chain — and Escape triggers the skip action, but only when `skipButtonText` is non-nil and
  `allowsInteractiveDismissal` is `true`. A blocking setup flow stays blocked, and Escape never
  fires a callback with nothing on screen to match it. Mac users can now complete or leave the
  sheet without a pointer.
- A light impact on the primary action on iOS. The skip button gets none, and macOS is unchanged.
- macOS pointer feedback on the skip button. The primary button gets hover from the system button
  style; the borderless skip button now takes the link pointer so it reads as clickable.

### Changed

- **Breaking.** The primary button is now the system prominent glass button
  (`.buttonStyle(.glassProminent)`) instead of a hand-drawn pill. `GreetStyle.tint` colors it, and
  the platform supplies the pressed, hovered, focused, disabled, and Increase Contrast treatments
  it previously faked. On macOS the button now reacts to the pointer and takes a focus ring.
- The animated gradient stops drawing on macOS while the app is inactive. It was running a 30fps
  `Canvas` behind whatever window the person had moved on to. Resuming is seamless because the phase
  still comes from the timeline date rather than being pinned.
- The app icon clips with a continuous corner curve, matching the squircle Apple uses for app icons.
  It was the one rounded rectangle in the package still using the circular-arc default.
- `GreetBackground.system` draws nothing instead of painting an opaque window or system background
  colour full-bleed. Sheets carry their own material on both platforms, and covering it is what made
  the default presentation look unlike a system sheet.
- Motion splits by platform. `Tokens.Motion` was the only token group with no platform branch, so
  the Mac got the iPhone's 38pt staggered reveal. macOS now travels 20pt instead and brings the
  first row in almost immediately, taking its pace from the gap between rows rather than an initial
  wait, so the sheet never looks slow to draw.

### Fixed

- The primary button no longer churns the layout while a loading state is possible. The progress
  indicator sat beside the label in a stack, so the button sized to `max(label, spinner)` — and an
  indeterminate `ProgressView` reports a size that varies by a fraction of a point as it animates.
  The two heights were close enough that the max flipped every frame, re-measuring the button, the
  footer, and the whole bottom bar over 11,000 times a minute across a full point of travel. The
  spinner is now an overlay, so it takes its size from the label and contributes nothing back.
- The primary button no longer shifts its label when loading starts. The loading state laid out a
  second copy of the label beside the spinner, and centring that pair moved the text sideways while
  two copies cross-faded through each other — under a glass material that read as the button
  wobbling. The label and the spinner now cross-fade in place. The label is hidden while loading;
  `primaryButtonLoadingAccessibilityValue` still announces the state to VoiceOver.
- The feature reveal stopped cascading after the fourth row. `maxFeatureStaggerDelay` capped the
  stagger so early that every row past the cap started on the same frame, so a longer feature list
  faded in as a block instead of revealing top to bottom. Around eight rows now get their own start
  time on both platforms — more than a viewport holds.
- The route transition uses a spring (`.smooth`) and the built-in `.push(from:)` rather than
  `.easeInOut` over a hand-built asymmetric move-and-fade. The feature reveal keeps its ease-out
  curve: it is a one-shot entrance nothing can interrupt, and a spring's tail reads as the row
  drifting after it has arrived.
- macOS sheets are window shaped. The 320x620 floor was an iPhone aspect on a desktop; the minimum
  is now 480x420 with an ideal of 560x520, and the sheet also reports an ideal size instead of only
  a minimum. Override it with `.presentationSizing(_:)` on the presentation.
- The minimum control height splits by platform: 44pt stays on iOS as a touch target, macOS uses
  28pt as a pointer target.
- macOS shows the system scroll indicator again when the greet content overflows. Hiding it made a
  Mac window unable to say there was more below, especially with a mouse and always-visible
  scrollers. iOS still hides it.
- The pinned footer now uses `safeAreaBar(edge:)` and the platform's hard scroll edge effect
  (`scrollEdgeEffectStyle(.hard, for: .bottom)`) instead of a measured mask, so overflowing content
  is separated from the footer the way the OS separates it everywhere else. The overview and the
  route destinations no longer wrap themselves in a `GeometryReader`.

### Removed

- **Breaking.** `GreetStyle.primaryButtonProgressTint`. The in-button progress view now inherits a
  legible color from the button style, so the previous hardcoded `.white` fallback is gone.
  `primaryButtonForegroundColor` remains as an opt-in override of the label color.

## [1.0.0] - 2026-07-24

First tagged release. Everything before this tag was consumed from the `master` branch.

### Added

- `GreetView` — the welcome sheet, with three initializers: a plain sheet, a single
  `primaryDestination`, and a `primaryRouteDestination` chain with `onPrimaryRoutesComplete`.
- `GreetContent` — the content protocol, with defaults for `appIcon`, `subtitle`, `primaryRoutes`,
  `primaryRouteNextButtonText`, `primaryRouteDoneButtonText`, `primaryButtonLoadingAccessibilityValue`,
  and `skipButtonText`.
- `GreetFeatureItem` and `GreetPrimaryRoute` — content models keyed by a stable `id`.
- `GreetBackground` — `.system`, `.softGradient`, `.linearGradient`, `.animatedGradient`, and `.custom`,
  applied with `greetBackground(_:)`.
- `GreetGradientPalette` and `GreetGradientMotion` for tuning the gradient backgrounds.
- `GreetStyle` — foreground and tint roles, applied with `greetStyle(_:)`.
- `primaryButtonLoadingAccessibilityValue` on `GreetContent`, so the VoiceOver value announced while
  the primary button is loading comes from the app instead of a hardcoded English string.
- GitHub Actions CI running the macOS build, the test suite, and an iOS build.

### Fixed

- The skip button now hit-tests across its full 44pt minimum control height. Previously only the text
  glyphs were tappable, so the reserved height below the label did nothing.
- The route chain no longer keys its transition animation off a route that is not on screen. Because
  `primaryRoutes` is a computed property, a route could disappear while it was open and leave the view
  showing the overview while the animation phase still named the missing route.

### Changed

- Route navigation state moved into an internal `GreetRouteState` value type, covered by unit tests.
- The primary button and the responsive horizontal padding are each defined once and shared by the
  overview footer and the route destinations.
- Replaced two soft-deprecated SwiftUI calls: `ScrollView(_:showsIndicators:)` (the
  `scrollIndicators(_:axes:)` modifier was already applied) and `Color(_ color: UIColor)`.
- `GreetStyle`, `GreetGradientPalette`, `GreetBackgroundContext`, `GreetFeatureItem`, and
  `GreetPrimaryRoute` are now `Sendable`. `GreetBackground` is not, because `.custom` stores a closure
  returning `AnyView`, which SwiftUI declares as `~Sendable`.

### Removed

- The two ID-less `GreetFeatureItem` initializers. They generated a fresh `UUID().uuidString` on every
  evaluation, which defeats SwiftUI's diffing for a `features` array built in a computed property. Pass
  a stable `id:` instead.
- `GreetBackground.animatedMesh(primary:secondary:accent:)`. Use
  `animatedGradient(brand:palette:motion:)` instead.

  Both were already marked deprecated and are removed here rather than after 1.0.0, since no tagged
  release ever shipped them.

[unreleased]: https://github.com/hksw-io/GreetKit/compare/2.0.1...HEAD
[2.0.1]: https://github.com/hksw-io/GreetKit/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/hksw-io/GreetKit/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/hksw-io/GreetKit/releases/tag/1.0.0
