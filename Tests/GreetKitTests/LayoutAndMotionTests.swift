#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

@Suite("Layout and motion")
struct LayoutAndMotionTests {
    @Test
    func revealDelayStartsWithBaseDelay() {
        #expect(Tokens.Motion.revealDelay(for: 0) == Tokens.Motion.featureBaseDelay)
    }

    @Test
    func revealDelayCapsLongLists() {
        let expectedDelay = Tokens.Motion.featureBaseDelay + Tokens.Motion.maxFeatureStaggerDelay
        let actualDelay = Tokens.Motion.revealDelay(for: 100)

        #expect(abs(actualDelay - expectedDelay) < 0.0001)
    }

    @Test
    func revealDelayTreatsNegativeIndexesAsFirst() {
        #expect(Tokens.Motion.revealDelay(for: -3) == Tokens.Motion.featureBaseDelay)
    }

    /// The reveal should read as a soft cascade, so both platforms take about a second to
    /// finish. Rushing the stagger collapses it into rows arriving at once, which is worse than
    /// not staggering at all. What macOS cuts is the travel, not the pace.
    @Test
    func revealIsASlowSoftStagger() {
        let lastRowSettles = Tokens.Motion.revealDelay(for: 100) + Tokens.Motion.revealDuration

        #expect(lastRowSettles > 1)
        #expect(Tokens.Motion.revealDuration >= 0.45)

        // The gap between rows has to be a real fraction of the fade, or each arrival smears into
        // its neighbours and the cascade reads as one fade rather than a stagger.
        #expect(Tokens.Motion.featureStaggerDelay >= Tokens.Motion.revealDuration * 0.3)

        // And the cap has to let enough rows have their own start time. Capping early makes every
        // row past the cap fire on the same frame, which is the same failure by another route.
        let distinctlyStaggeredRows =
            Tokens.Motion.maxFeatureStaggerDelay / Tokens.Motion.featureStaggerDelay
        #expect(distinctlyStaggeredRows >= 6)

        #if os(macOS)
            #expect(Tokens.Motion.revealOffset == 20)
            #expect(lastRowSettles < 2.1)
            // The first row arrives promptly — a wait before anything happens reads as the sheet
            // being slow to draw. The pace comes from the gap between rows instead.
            #expect(Tokens.Motion.featureBaseDelay <= 0.1)
            #expect(Tokens.Motion.featureStaggerDelay > Tokens.Motion.featureBaseDelay)
        #else
            #expect(Tokens.Motion.revealOffset == 38)
            #expect(lastRowSettles < 2.1)
        #endif
    }

    /// The padding follows the horizontal size class, which is known on the first layout pass. It
    /// used to follow a measured width, which arrived a pass late: phones wider than the old
    /// breakpoint started at the compact padding and jumped to the regular one.
    @Test
    @MainActor
    func horizontalPaddingFollowsTheSizeClass() {
        #expect(Self.paddedWidth(in: .compact) == 100 + 2 * Tokens.Layout.compactHorizontalPadding)
        #expect(Self.paddedWidth(in: .regular) == 100 + 2 * Tokens.Layout.regularHorizontalPadding)
    }

    @MainActor
    private static func paddedWidth(in sizeClass: UserInterfaceSizeClass) -> CGFloat {
        let view = Color.clear
            .frame(width: 100, height: 10)
            .greetHorizontalPadding()
            .environment(\.horizontalSizeClass, sizeClass)
            .dynamicTypeSize(.large)

        #if os(macOS)
            return NSHostingView(rootView: view).fittingSize.width
        #else
            return UIHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: 1000, height: 1000)).width
        #endif
    }

    /// The subtitle belongs to the title. It has to sit closer to it than the icon does, or the
    /// header reads as three unrelated items.
    @Test
    func subtitleSitsCloserToTheTitleThanTheIconDoes() {
        #expect(Tokens.Spacing.small < Tokens.Spacing.large)
    }

    /// Content at the end of the scroll view rests `bottomPadding` above the footer. A fade taller
    /// than that would dim the last row even when nothing is scrolling under it.
    @Test
    func footerFadeStopsShortOfContentAtRest() {
        #expect(Tokens.Layout.footerFadeHeight <= Tokens.Platform.bottomPadding)
    }

    @Test
    func footerControlsUseCompactVisualSpacingWithAccessibleSkipHeight() {
        #expect(Tokens.Layout.footerControlSpacing == Tokens.Spacing.medium)

        #if os(macOS)
            // A pointer target, not a touch target.
            #expect(Tokens.Platform.minimumControlHeight == 28)
        #else
            #expect(Tokens.Platform.minimumControlHeight == 44)
        #endif
    }

    /// The button must clear the sheet edge rather than hug it, without floating so high that the
    /// bar looks detached. Without a skip button under the primary one, nothing else holds it off
    /// the edge.
    @Test
    func footerUsesAsymmetricPaddingThatStillClearsTheBottomEdge() {
        #expect(Tokens.Layout.footerBottomPadding > 0)
        #expect(Tokens.Layout.footerBottomPadding < Tokens.Layout.footerTopPadding)
    }

    /// The Mac floor is a window shape, not a phone shape: wider than it is tall. iOS sets no
    /// floor — the presentation owns the size there.
    #if os(macOS)
        @Test
        func macSheetMinimumsAreWindowShaped() {
            #expect(Tokens.Platform.sheetMinWidth > Tokens.Platform.sheetMinHeight)
            #expect(Tokens.Platform.sheetIdealWidth >= Tokens.Platform.sheetMinWidth)
            #expect(Tokens.Platform.sheetIdealHeight >= Tokens.Platform.sheetMinHeight)
        }
    #endif
}
#endif
