#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

@Suite("Greet page")
@MainActor
struct GreetPageTests {
    /// One smoke test over the widest surface the page offers: both slots filled, a scrolling
    /// content view, the skip style in the footer, a background and an ordinary tint.
    @Test
    func pageConstructsAcrossItsFullSurface() {
        _ = Self.page(subtitle: Text("Choose when to be reminded."))
            .greetBackground(.softGradient(brand: .orange))
            .tint(.indigo)
    }

    #if os(macOS)
        /// On Mac the page follows the welcome sheet, so it has to ask for the same window. Hosting
        /// it also runs the body, which construction alone does not.
        @Test
        func pageAsksForTheWelcomeSheetSizeOnMac() {
            let welcome = NSHostingView(rootView: GreetView(
                content: PageTestContent(),
                isLoading: .constant(false),
                errorMessage: .constant(nil),
                onPrimary: {},
                onSkip: {}))
            let page = NSHostingView(rootView: Self.page(subtitle: nil))

            #expect(page.fittingSize == welcome.fittingSize)
            #expect(page.fittingSize == CGSize(
                width: Tokens.Platform.sheetIdealWidth,
                height: Tokens.Platform.sheetIdealHeight))
        }
    #endif

    private static func page(subtitle: Text?) -> GreetPage<some View, some View> {
        GreetPage(title: Text("Daily Reminder"), subtitle: subtitle) {
            List {
                Text("Row")
            }
            .scrollContentBackground(.hidden)
        } footer: {
            Button("Continue") {}
            Button("Not Now") {}
                .buttonStyle(.greetSkip)
        }
    }
}

private struct PageTestContent: GreetContent {
    var title: Text { Text("Welcome") }
    var features: [GreetFeatureItem] { [] }
    var primaryButtonText: Text { Text("Get started") }
    var errorAlertTitle: Text { Text("Error") }
    var errorOKText: Text { Text("OK") }
}
#endif
