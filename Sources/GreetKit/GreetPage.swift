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
/// The title and footer do not scroll with the content, so where height is short, at large text
/// sizes or on an iPhone in landscape, the title gives way first: it scrolls in a shorter band and
/// the content keeps room for at least two list rows.
///
/// The page presents, dismisses and animates nothing. The app owns all of that.
public struct GreetPage<Content: View, Footer: View>: View {
    let title: Text
    let subtitle: Text?
    let content: Content
    let footer: Footer
    private var background: GreetBackground = .system

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Unlike `GreetView`'s, the gaps around the title do not grow with the text size. Here they
    // are not scrolled away, so every point they grew by came out of the content.
    @ScaledMetric(relativeTo: .body) private var minimumContentHeight: CGFloat =
        Tokens.Layout.pageMinimumContentHeight

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
        // The gap under the title starts inside its scroll view, so that the fade at the bottom of
        // the scroll view only ever falls on the gap while the title has its full height.
        GreetPageLayout(
            spacing: max(0, self.contentSpacing - Tokens.Layout.footerFadeHeight),
            minimumContentHeight: self.minimumContentHeight + Tokens.Platform.bottomPadding)
        {
            // Scrolls only once the layout gives it less than its full height, and then fades out
            // at the bottom like the content does above the footer, rather than being cut off.
            ScrollView(.vertical) {
                GreetTitleBlock(title: self.title, subtitle: self.subtitle)
                    .textSelection(.enabled)
                    .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .greetHorizontalPadding()
                    .padding(.top, self.topPadding)
                    .padding(.bottom, Tokens.Layout.footerFadeHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .mask { GreetFooterFade() }

            // The bottom padding joins the safe area rather than shrinking the slot. Fixed content
            // stops above it either way, but a scroll view scrolls through the fade and rests
            // clear of it at the end, as the welcome screen's own rows do.
            self.content
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .greetHorizontalPadding()
                .safeAreaPadding(.bottom, Tokens.Platform.bottomPadding)
                // A scroll view here runs on under the footer and the home indicator, where the
                // fade hides it. A mask does not stop touches, and the footer only takes the ones
                // inside its own frame, so a touch below it reached rows nobody could see. Taking
                // the content's touches only inside its slot stops that.
                .contentShape(.rect)
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

    /// An iPhone in landscape has too little height for the welcome screen's generous gaps.
    private var isCompactHeight: Bool {
        self.verticalSizeClass == .compact
    }

    private var topPadding: CGFloat {
        self.isCompactHeight ? Tokens.Spacing.large : Tokens.Platform.topPadding
    }

    private var contentSpacing: CGFloat {
        self.isCompactHeight ? Tokens.Spacing.large : Tokens.Platform.contentSpacing
    }

    /// Sets the surface drawn behind the page, edge to edge. Defaults to `.system`.
    public func greetBackground(_ background: GreetBackground) -> Self {
        var view = self
        view.background = background
        return view
    }
}

/// Stacks a page's header over its content, and lets the header give way when both do not fit.
///
/// The header gets its full height while the content keeps `minimumContentHeight`. Past that it
/// shrinks and scrolls, but never below a quarter of the height, so the title stays in reach.
struct GreetPageLayout: Layout {
    let spacing: CGFloat
    let minimumContentHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let header = subviews[0]
        let content = subviews[1]

        let idealHeaderHeight = header.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)).height
        let headerHeight = Self.headerHeight(
            ideal: idealHeaderHeight,
            available: bounds.height,
            spacing: self.spacing,
            minimumContentHeight: self.minimumContentHeight)
        let contentTop = headerHeight + self.spacing

        header.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: headerHeight))
        content.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY + contentTop),
            proposal: ProposedViewSize(width: bounds.width, height: max(0, bounds.height - contentTop)))
    }

    static func headerHeight(
        ideal: CGFloat,
        available: CGFloat,
        spacing: CGFloat,
        minimumContentHeight: CGFloat) -> CGFloat
    {
        let floor = min(ideal, available / 4)
        return min(ideal, max(available - spacing - minimumContentHeight, floor))
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
