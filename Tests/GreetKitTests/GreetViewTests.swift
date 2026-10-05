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
            isLoading: .constant(true),
            errorMessage: .constant("Network offline"),
            allowsInteractiveDismissal: false,
            onPrimary: {},
            onSkip: {},
            onPrimaryRoutesComplete: {},
            primaryRouteDestination: { route in
                Text(route.id)
            })
            .greetBackground(.animatedGradient(brand: .orange))
            .greetStyle(GreetStyle(tint: .indigo))
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
    func primaryRouteStoresStableID() {
        let route = GreetPrimaryRoute(id: "sample-data")

        #expect(route.id == "sample-data")
    }

    @Test
    func contentProtocolSuppliesDefaultsForOptionalMembers() {
        struct DefaultsContent: GreetContent {
            var title: Text { Text("Defaults") }
            var features: [GreetFeatureItem] { [] }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        let content = DefaultsContent()

        #expect(content.appIcon == nil)
        #expect(content.subtitle == nil)
        #expect(content.skipButtonText == nil)
        #expect(content.footnote == nil)
        #expect(content.primaryRoutes.isEmpty)
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
    var primaryRoutes: [GreetPrimaryRoute] {
        [
            GreetPrimaryRoute(id: "permissions"),
            GreetPrimaryRoute(id: "sample-data"),
        ]
    }
    var primaryButtonText: Text { Text("Get started") }
    var primaryRouteNextButtonText: Text { Text("Next step") }
    var primaryRouteBackButtonText: Text { Text("Previous step") }
    var primaryRouteDoneButtonText: Text { Text("Finish") }
    var primaryButtonLoadingAccessibilityValue: Text { Text("Laddar") }
    var skipButtonText: Text? { Text("Skip") }
    var footnote: Text? { Text("Footnote.") }
    var errorAlertTitle: Text { Text("Something went wrong") }
    var errorOKText: Text { Text("OK") }
}
#endif
