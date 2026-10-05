#if os(iOS) || os(macOS)
import SwiftUI

enum Tokens {
    enum Spacing {
        /// Between a title and the subtitle that belongs to it. Tighter than the gap around the
        /// icon, so the two read as one heading rather than as two separate items.
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    enum Radius {
        static let iconScale: CGFloat = 0.22
    }

    enum Layout {
        static let contentMaxWidth: CGFloat = 560
        static let compactHorizontalPadding: CGFloat = 16
        static let regularHorizontalPadding: CGFloat = 24
        static let compactWidthBreakpoint: CGFloat = 390

        static func isCompact(width: CGFloat) -> Bool {
            width <= compactWidthBreakpoint
        }
        static let footerControlSpacing: CGFloat = Spacing.medium
        /// How far above the footer scrolling content fades out. No taller than the content's
        /// bottom padding, so content resting at the end of the scroll view is never faded.
        static let footerFadeHeight: CGFloat = 20
        static let footerTopPadding: CGFloat = 20
        /// The button needs to sit off the sheet edge, not against it. On the overview the skip
        /// button hid this, but a route page has no skip, so the primary button landed on the edge.
        static let footerBottomPadding: CGFloat = Spacing.large
    }

    /// Kept here rather than in `Platform` so the shared `revealDelay(for:)` stays next to the
    /// values it composes.
    enum Motion {
        #if os(macOS)
            // A Mac sheet travels less than a phone one — 14pt rather than 38 — but it still
            // reveals at a readable pace.
            //
            // The first row arrives essentially at once: a wait before anything happens reads as
            // the sheet being slow to draw, not as choreography.
            //
            // Three things make the cascade read as a stagger rather than a fade. The gap between
            // rows is a large fraction of the fade duration, so each arrival is distinct instead
            // of smeared into its neighbours. The cap is high enough that around eight rows get
            // their own start time — capping early makes every row past it fire at once, which is
            // precisely what turns a stagger back into a fade. And the travel is far enough to be
            // seen as movement; a row that only fades has nothing to stagger visually.
            static let featureBaseDelay: Double = 0.04
            static let featureStaggerDelay: Double = 0.18
            static let maxFeatureStaggerDelay: Double = 1.44
            static let revealDuration: Double = 0.45
            static let revealOffset: CGFloat = 20
            static let routeTransitionDuration: Double = 0.26
        #else
            static let featureBaseDelay: Double = 0.3
            static let featureStaggerDelay: Double = 0.17
            // Eight rows deep rather than four. At four, every row past the fourth started at the
            // same instant, so a long feature list stopped cascading and just faded in.
            static let maxFeatureStaggerDelay: Double = 1.19
            static let revealDuration: Double = 0.48
            static let revealOffset: CGFloat = 38
            static let routeTransitionDuration: Double = 0.32
        #endif

        static func revealDelay(for index: Int) -> Double {
            let staggerDelay = min(Double(max(0, index)) * self.featureStaggerDelay, self.maxFeatureStaggerDelay)
            return self.featureBaseDelay + staggerDelay
        }
    }

    enum Platform {
        #if os(macOS)
            static let iconSize: CGFloat = 64
            static let featureIconSize: CGFloat = 24
            static let contentSpacing: CGFloat = 24
            static let featureSpacing: CGFloat = 20
            static let topPadding: CGFloat = 32
            static let bottomPadding: CGFloat = 20
            /// A Mac window is wider than it is tall. The old 320x620 floor was an iPhone
            /// shape on a desktop.
            static let sheetMinWidth: CGFloat = 480
            static let sheetMinHeight: CGFloat = 420
            static let sheetIdealWidth: CGFloat = 560
            static let sheetIdealHeight: CGFloat = 520
            /// What to assume before the container reports its width, so the first layout pass
            /// already picks the padding the measured pass will confirm. A Mac sheet is never
            /// narrower than `sheetMinWidth`, which is past the compact breakpoint.
            static let assumedContainerWidth: CGFloat = sheetIdealWidth
            /// A pointer target, not a touch target.
            static let minimumControlHeight: CGFloat = 28
        #else
            static let iconSize: CGFloat = 100
            static let featureIconSize: CGFloat = 35
            static let contentSpacing: CGFloat = 38
            static let featureSpacing: CGFloat = 32
            static let topPadding: CGFloat = 32
            static let bottomPadding: CGFloat = 24
            static let minimumControlHeight: CGFloat = 44
            /// Phone width, which is what a sheet is on the overwhelming majority of iOS
            /// presentations. iPad still corrects itself on the measured pass.
            static let assumedContainerWidth: CGFloat = 0
        #endif
    }

    static var background: Color {
        #if os(macOS)
            Color(.windowBackgroundColor)
        #else
            Color(.systemBackground)
        #endif
    }
}
#endif
