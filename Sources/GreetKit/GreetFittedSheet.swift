#if os(iOS) || os(macOS)
import SwiftUI

public extension View {
    /// Sizes the presentation to the height of the welcome screen's content, so a short feature
    /// list gets a short sheet instead of a tall one with empty space, and a longer list gets the
    /// room it needs instead of scrolling in a short one.
    ///
    /// Apply it to the `GreetView` inside the sheet, after `greetBackground(_:)`:
    ///
    /// ```swift
    /// .sheet(isPresented: $showingGreet) {
    ///     GreetView(content: MyGreet(), onPrimary: { showingGreet = false })
    ///         .greetFittedSheet()
    /// }
    /// ```
    ///
    /// The height is the scrolling content plus the pinned footer. On iPhone it becomes the sheet's
    /// only detent; on iPad and Mac the sheet fits it. Content taller than the screen still gets a
    /// full-height sheet and scrolls. The height is also offered as the view's ideal height, so a
    /// hosting controller sized with `sizingOptions = .preferredContentSize` fits the same way.
    ///
    /// It measures the scroll view `GreetView` owns. A `GreetPage` keeps its title outside whatever
    /// scrolls in its content, so this modifier is not for it.
    func greetFittedSheet() -> some View {
        self.modifier(GreetFittedSheet())
    }
}

/// Kept in step with ReleaseKit's `ReleaseFittedSheet`, so the two sheets fit the same way.
struct GreetFittedSheet: ViewModifier {
    /// `nil` until the scroll view reports its geometry, which leaves the view's own sizing alone.
    @State private var height: CGFloat?

    func body(content: Content) -> some View {
        content
            // The footer is a safe-area bar, so its height arrives as the scroll view's bottom
            // inset rather than as part of the content size.
            //
            // ponytail: on an iPhone that inset also holds the home-indicator safe area, which the
            // detent adds again, so the sheet is one such inset (about 30pt) taller than the
            // content. Subtract the container's bottom safe area if a tighter fit is ever wanted.
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom
            } action: { _, height in
                self.height = height
            }
            .frame(idealHeight: self.height.map(Self.idealHeight))
        #if os(iOS)
            .presentationDetents([self.height.map { .height($0) } ?? .large])
        #endif
            .presentationSizing(.form.fitted(horizontal: false, vertical: true))
    }

    /// The Mac sheet lays out at least `sheetMinHeight` tall, so a shorter fit would clip its
    /// footer.
    static func idealHeight(for contentHeight: CGFloat) -> CGFloat {
        #if os(macOS)
            max(contentHeight, Tokens.Platform.sheetMinHeight)
        #else
            contentHeight
        #endif
    }
}
#endif
