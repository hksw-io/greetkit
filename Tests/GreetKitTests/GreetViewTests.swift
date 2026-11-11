#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

@Suite("Greet view construction")
@MainActor
struct GreetViewTests {
    /// One smoke test over the widest surface the view offers, rather than one per combination.
    /// Whether a given call site compiles is decided by the compiler, so a test whose whole body is
    /// `_ = GreetView(...)` asserts nothing the test target building has not already proved.
    @Test
    func viewConstructsAcrossItsFullSurface() {
        _ = GreetView(
            content: RichContent(),
            isLoading: true,
            errorMessage: .constant("Network offline"),
            allowsInteractiveDismissal: false,
            onPrimary: {},
            onSkip: {})
            .greetBackground(.softGradient(brand: .orange))
            .greetFittedSheet()
            .tint(.indigo)
    }

    /// The fitted height follows the content, except that a Mac sheet never lays out shorter than
    /// its floor, so offering less would clip the footer.
    @Test
    func fittedSheetFollowsContentAboveTheMacFloor() {
        #expect(GreetFittedSheet.idealHeight(for: 900) == 900)

        #if os(macOS)
            #expect(GreetFittedSheet.idealHeight(for: 100) == Tokens.Platform.sheetMinHeight)
        #else
            #expect(GreetFittedSheet.idealHeight(for: 100) == 100)
        #endif
    }

    /// An app with no loading state, no error and no skip button passes none of them.
    @Test
    func viewNeedsOnlyContentAndThePrimaryAction() {
        let view = GreetView(content: RichContent(), onPrimary: {})

        #expect(!view.isLoading)
        #expect(view.errorMessage == nil)
        #expect(view.allowsInteractiveDismissal)
    }

    /// Skip and Escape are disabled while loading. A swipe that dismissed the sheet mid-load would
    /// get around both.
    @Test
    func interactiveDismissalIsBlockedWhileLoading() {
        let idle = GreetView(content: RichContent(), onPrimary: {})
        let loading = GreetView(content: RichContent(), isLoading: true, onPrimary: {})
        let blocking = GreetView(content: RichContent(), allowsInteractiveDismissal: false, onPrimary: {})

        #expect(!idle.blocksInteractiveDismissal)
        #expect(loading.blocksInteractiveDismissal)
        #expect(blocking.blocksInteractiveDismissal)
    }

    @Test
    func featureInitializerStoresStableID() {
        let feature = GreetFeatureItem(
            id: "stable-feature",
            label: Text("Stable feature"),
            description: Text("A feature with stable identity."))

        #expect(feature.id == "stable-feature")
    }

    @Test
    func convenienceFeatureInitializerStoresStableID() {
        let feature = GreetFeatureItem(
            id: "localized-feature",
            systemImage: "sparkles",
            label: "Label",
            description: "Description.")

        #expect(feature.id == "localized-feature")
        #expect(feature.image != nil)
        #expect(feature.label != nil)
    }

    @Test
    func featureOmitsOptionalIconAndLabel() {
        let feature = GreetFeatureItem(id: "bare", description: Text("Description only."))

        #expect(feature.image == nil)
        #expect(feature.label == nil)
    }

    @Test
    func contentProtocolSuppliesDefaultsForOptionalMembers() {
        struct DefaultsContent: GreetContent {
            var title: Text { Text("Defaults") }
            var features: [GreetFeatureItem] { [] }
            var primaryButtonText: Text { Text("Go") }
            var primaryButtonLoadingAccessibilityValue: Text { Text("Loading") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        let content = DefaultsContent()

        #expect(content.appIcon == nil)
        #expect(content.subtitle == nil)
        #expect(content.skipButtonText == nil)
        #expect(content.footnote == nil)
    }
}

private struct RichContent: GreetContent {
    var appIcon: Image? { Image(systemName: "app.gift.fill") }
    var title: Text { Text("Welcome") }
    var subtitle: Text? { Text("Subtitle line.") }
    var features: [GreetFeatureItem] {
        [
            GreetFeatureItem(
                id: "with-label",
                image: Image(systemName: "star"),
                label: Text("Label"),
                description: Text("Description.")),
            GreetFeatureItem(id: "bare", description: Text("Description only.")),
        ]
    }
    var primaryButtonText: Text { Text("Get started") }
    var primaryButtonLoadingAccessibilityValue: Text { Text("Laddar") }
    var skipButtonText: Text? { Text("Skip") }
    var footnote: Text? { Text("Footnote.") }
    var errorAlertTitle: Text { Text("Something went wrong") }
    var errorOKText: Text { Text("OK") }
}
#endif
