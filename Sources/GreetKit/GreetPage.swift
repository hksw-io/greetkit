#if os(iOS) || os(macOS)
import SwiftUI

/// A page in the welcome screen's look, for a screen the app builds itself: a permission step or a
/// choice of settings that follows the welcome.
///
/// It draws the same background, title type, paddings, pinned footer and Mac sheet size as
/// `GreetView`, and leaves everything between the title and the footer to the app. The content is
/// placed as given, with no scroll view around it, so a `List`, a `Form` or a `ScrollView` scrolls
/// under the footer's fade by itself. Buttons in the footer take the tint from the environment, so
/// set the brand colour with SwiftUI's own `tint(_:)`.
///
/// The page presents, dismisses and animates nothing. The app owns all of that.
public struct GreetPage<Content: View, Footer: View>: View {
    let title: Text
    let subtitle: Text?
    let content: Content
    let footer: Footer
    private var background: GreetBackground = .system

    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding

    /// - Parameters:
    ///   - title: Shown centred at the top, and exposed to VoiceOver as a header.
    ///   - subtitle: An optional line under the title.
    ///   - content: The app's own content, held to the welcome screen's width.
    ///   - footer: Controls pinned to the bottom, stacked with the welcome screen's spacing.
    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer)
    {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: self.contentSpacing) {
            GreetTitleBlock(title: self.title, subtitle: self.subtitle)
                .textSelection(.enabled)
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .greetHorizontalPadding()
                .padding(.top, self.topPadding)

            // The bottom padding joins the safe area rather than shrinking the slot. Fixed content
            // stops above it either way, but a scroll view scrolls through the fade and rests
            // clear of it at the end, as the welcome screen's own rows do.
            self.content
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .greetHorizontalPadding()
                .safeAreaPadding(.bottom, self.bottomPadding)
        }
        .greetScrollIndicators()
        .mask { GreetFooterFade() }
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: Tokens.Layout.footerControlSpacing) {
                self.footer
            }
            .padding(.top, Tokens.Layout.footerTopPadding)
            .padding(.bottom, Tokens.Layout.footerBottomPadding)
            .frame(maxWidth: Tokens.Layout.contentMaxWidth)
            .greetHorizontalPadding()
            .frame(maxWidth: .infinity)
        }
        .scrollEdgeEffectHidden(true, for: .bottom)
        .greetSheetSizing()
        .background {
            GreetBackgroundView(background: self.background)
        }
    }

    /// Sets the surface drawn behind the page, edge to edge. Defaults to `.system`.
    public func greetBackground(_ background: GreetBackground) -> Self {
        var view = self
        view.background = background
        return view
    }
}

/// The look of the welcome screen's skip action: body text in the tint colour, across the full
/// width, with the platform's minimum control height as its hit area.
///
/// For a second action in a `GreetPage` footer, such as Not Now. It wraps the system plain button,
/// so the pressed and disabled treatments are the platform's.
public struct GreetSkipButtonStyle: PrimitiveButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label.greetSkipLabel()
        }
        .greetSkipChrome()
    }
}

public extension PrimitiveButtonStyle where Self == GreetSkipButtonStyle {
    /// The look of the welcome screen's skip action. See ``GreetSkipButtonStyle``.
    static var greetSkip: Self { Self() }
}

#Preview("Greet Page") {
    GreetPage(title: Text("Daily Reminder"), subtitle: Text("Choose when to be reminded to study.")) {
        List {
            Toggle("Remind Me", isOn: .constant(true))
            LabeledContent("Time", value: "19:00")
        }
        .scrollContentBackground(.hidden)
    } footer: {
        Button("Continue") {}
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .buttonSizing(.flexible)
            .controlSize(.large)
        Button("Not Now") {}
            .buttonStyle(.greetSkip)
    }
    .greetBackground(.softGradient)
    .tint(.indigo)
}
#endif
