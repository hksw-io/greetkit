#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

/// The page's title and footer do not scroll with the content, so they could take all the height
/// there is and leave the app's content none. These host the page at the tight sizes of an iPhone 17
/// Pro, safe areas already taken off, and measure what is left for the content.
///
/// Text does not grow with the type size on macOS, so the large-text cases only bite on iOS.
@Suite("Greet page layout")
@MainActor
struct GreetPageLayoutTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let name: String
        let size: CGSize
        let dynamicTypeSize: DynamicTypeSize
        let verticalSizeClass: UserInterfaceSizeClass

        var testDescription: String { self.name }
    }

    nonisolated static let cases = [
        Case(
            name: "portrait at AX5",
            size: CGSize(width: 402, height: 874 - 62 - 34),
            dynamicTypeSize: .accessibility5,
            verticalSizeClass: .regular),
        Case(
            name: "landscape",
            size: CGSize(width: 874 - 2 * 62, height: 402 - 21),
            dynamicTypeSize: .large,
            verticalSizeClass: .compact),
        Case(
            name: "landscape at AX1",
            size: CGSize(width: 874 - 2 * 62, height: 402 - 21),
            dynamicTypeSize: .accessibility1,
            verticalSizeClass: .compact),
    ]

    @Test(arguments: cases)
    func contentKeepsAtLeastTwoRows(_ testCase: Case) async throws {
        let probe = Probe()
        let page = GreetPage(
            title: Text("Daily Reminder"),
            subtitle: Text("Choose when to be reminded to study."))
        {
            Color.clear
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { probe.contentHeight = $0 }
        } footer: {
            Button("Continue") {}
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .controlSize(.large)
            Button("Not Now") {}
                .buttonStyle(.greetSkip)
        }
        .environment(\.verticalSizeClass, testCase.verticalSizeClass)

        let rowText = Text("Remind Me").font(.body)
        let rowTextHeight = Self.hostedSize(of: rowText, typeSize: testCase.dynamicTypeSize).height
        // A list row is its text with the system's 11 pt above and below, and never under 44 pt.
        let twoRows = 2 * max(44, rowTextHeight + 22)

        Self.host(page, size: testCase.size, typeSize: testCase.dynamicTypeSize)
        try await Task.sleep(for: .milliseconds(100))

        let contentHeight = try #require(probe.contentHeight)
        #expect(contentHeight >= twoRows, "\(contentHeight) pt is less than two rows (\(twoRows) pt)")
    }

    @MainActor
    final class Probe {
        var contentHeight: CGFloat?
    }

    private static var hosts: [AnyObject] = []

    private static func host(_ view: some View, size: CGSize, typeSize: DynamicTypeSize) {
        let root = view.frame(width: size.width, height: size.height).dynamicTypeSize(typeSize)
        #if os(macOS)
            let host = NSHostingView(rootView: root)
            host.frame = CGRect(origin: .zero, size: size)
            host.layoutSubtreeIfNeeded()
        #else
            // Off screen, a hosting controller lays nothing out, so it gets a window of its own.
            let host = UIWindow(frame: CGRect(origin: .zero, size: size))
            host.rootViewController = UIHostingController(rootView: root)
            host.isHidden = false
            host.layoutIfNeeded()
        #endif
        // Kept alive until the geometry callbacks have run.
        self.hosts.append(host)
    }

    private static func hostedSize(of view: some View, typeSize: DynamicTypeSize) -> CGSize {
        let root = view.fixedSize().dynamicTypeSize(typeSize)
        #if os(macOS)
            return NSHostingView(rootView: root).fittingSize
        #else
            return UIHostingController(rootView: root).sizeThatFits(in: CGSize(width: 1000, height: 1000))
        #endif
    }
}
#endif
