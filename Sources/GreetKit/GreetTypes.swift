#if os(iOS) || os(macOS)
import SwiftUI

public struct GreetFeatureItem: Identifiable, Sendable {
    public let id: String
    public let image: Image?
    public let label: Text?
    public let description: Text

    public init(id: String, image: Image? = nil, label: Text? = nil, description: Text) {
        self.id = id
        self.image = image
        self.label = label
        self.description = description
    }

    public init(
        id: String,
        systemImage: String? = nil,
        label: LocalizedStringResource? = nil,
        description: LocalizedStringResource)
    {
        self.id = id
        self.image = systemImage.map { Image(systemName: $0) }
        self.label = label.map { Text($0) }
        self.description = Text(description)
    }
}

public struct GreetPrimaryRoute: Identifiable, Hashable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public protocol GreetContent {
    var appIcon: Image? { get }
    var title: Text { get }
    var subtitle: Text? { get }
    var features: [GreetFeatureItem] { get }
    var primaryRoutes: [GreetPrimaryRoute] { get }
    var primaryRouteNextButtonText: Text { get }
    /// Accessible name and pointer help for the back chevron.
    var primaryRouteBackButtonText: Text { get }
    var primaryRouteDoneButtonText: Text { get }
    var primaryButtonText: Text { get }
    var primaryButtonLoadingAccessibilityValue: Text { get }
    var skipButtonText: Text? { get }
    var errorAlertTitle: Text { get }
    var errorOKText: Text { get }
}

public extension GreetContent {
    var appIcon: Image? { nil }
    var subtitle: Text? { nil }
    var primaryRoutes: [GreetPrimaryRoute] { [] }
    var primaryRouteNextButtonText: Text { Text("Next") }
    var primaryRouteBackButtonText: Text { Text("Back") }
    var primaryRouteDoneButtonText: Text { Text("Done") }
    var primaryButtonLoadingAccessibilityValue: Text { Text("Loading") }
    var skipButtonText: Text? { nil }
}
#endif
