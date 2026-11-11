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

public protocol GreetContent {
    var appIcon: Image? { get }
    var title: Text { get }
    var subtitle: Text? { get }
    var features: [GreetFeatureItem] { get }
    var primaryButtonText: Text { get }
    /// What VoiceOver announces as the primary button's value while `isLoading` is `true`.
    var primaryButtonLoadingAccessibilityValue: Text { get }
    var skipButtonText: Text? { get }
    /// A sentence shown above the primary button, for when the actions need explaining.
    var footnote: Text? { get }
    var errorAlertTitle: Text { get }
    var errorOKText: Text { get }
}

public extension GreetContent {
    var appIcon: Image? { nil }
    var subtitle: Text? { nil }
    var skipButtonText: Text? { nil }
    var footnote: Text? { nil }
}
#endif
