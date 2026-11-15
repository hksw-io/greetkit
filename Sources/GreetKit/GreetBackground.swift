#if os(iOS) || os(macOS)
import SwiftUI

/// Flattens a decorative colour wash when the person has asked for a background that competes less
/// with the text on top of it.
///
/// Reduce Transparency and Increase Contrast both mean the same thing for a wash like this: damp
/// it, and let the opaque base carry more of the surface, so foreground contrast stops depending on
/// where the colour happens to sit.
struct GreetGradientDamping: Equatable, Sendable {
    static let none = Self(isActive: false)

    let isActive: Bool

    init(reduceTransparency: Bool, increaseContrast: Bool) {
        self.init(isActive: reduceTransparency || increaseContrast)
    }

    private init(isActive: Bool) {
        self.isActive = isActive
    }

    /// How much of the coloured wash survives.
    func tint(_ opacity: Double) -> Double {
        self.isActive ? opacity * 0.3 : opacity
    }

    /// How much more of the opaque base is pulled over the wash.
    func veil(_ opacity: Double) -> Double {
        self.isActive ? min(1, opacity + 0.25) : opacity
    }
}

/// The four colours a built-in gradient composites, derived from one brand colour.
///
/// The brand colour becomes `primary`, and the supporting tones are that same colour washed
/// toward the platform surface, so the field reads as one colour rather than as three unrelated
/// hues. Because the surface is light in light mode and dark in dark mode, the same wash lifts the
/// palette in one and deepens it in the other.
///
/// Dark mode washes less: a dark surface swallows chroma faster, so an equal mix would flatten the
/// supporting tones into the background.
struct GreetGradientTones {
    let base: Color
    let primary: Color
    let secondary: Color
    let accent: Color

    init(brand: Color, colorScheme: ColorScheme) {
        let secondaryMix = colorScheme == .dark ? 0.22 : 0.30
        let accentMix = colorScheme == .dark ? 0.42 : 0.55

        self.base = Tokens.background
        self.primary = brand
        self.secondary = brand.mix(with: Tokens.background, by: secondaryMix)
        self.accent = brand.mix(with: Tokens.background, by: accentMix)
    }
}

/// The three colours a mesh background spreads along its top edge.
struct GreetMeshColors: Sendable {
    let leading: Color
    let center: Color
    let trailing: Color
}

/// The surface drawn behind a `GreetView` or a `GreetPage`.
public struct GreetBackground: Sendable {
    enum Storage {
        case system
        case softGradient(brand: Color?)
        case mesh(GreetMeshColors)
    }

    let storage: Storage

    /// Draws nothing, so the presentation's own surface shows through.
    public static let system = Self(storage: .system)
    /// A restrained gradient in the default blue.
    public static let softGradient = Self(storage: .softGradient(brand: nil))
    /// A mesh in cyan, blue, and indigo.
    public static let mesh = Self.mesh()

    /// A restrained gradient derived from `brand`, or from blue without one.
    public static func softGradient(brand: Color? = nil) -> Self {
        Self(storage: .softGradient(brand: brand))
    }

    /// A mesh of three colours along the top edge, from leading to trailing, that settles into the
    /// platform surface below the title.
    public static func mesh(leading: Color = .cyan, center: Color = .blue, trailing: Color = .indigo) -> Self {
        Self(storage: .mesh(GreetMeshColors(leading: leading, center: center, trailing: trailing)))
    }
}

/// Draws a `GreetBackground` edge to edge, for `GreetView` and `GreetPage` alike.
///
/// It reads the accessibility environment itself, so neither caller forwards it.
struct GreetBackgroundView: View {
    let background: GreetBackground
    /// A page usually holds an inset grouped form, so its mesh settles into the grouped surface.
    var settlesIntoGroupedSurface = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme

    private var damping: GreetGradientDamping {
        GreetGradientDamping(
            reduceTransparency: self.reduceTransparency,
            increaseContrast: self.colorSchemeContrast == .increased)
    }

    var body: some View {
        switch self.background.storage {
        case .system:
            // Draw nothing. Sheets carry their own material on both platforms, and painting an
            // opaque colour over it is what made the default presentation look unlike a system
            // sheet. `Tokens.background` stays as the opaque base the gradient composites onto.
            EmptyView()
        case let .softGradient(brand):
            GreetSoftGradientBackground(
                // The gradient cannot read the tint back out of the environment, so without a
                // brand it is blue.
                tones: GreetGradientTones(brand: brand ?? .blue, colorScheme: self.colorScheme),
                colorScheme: self.colorScheme,
                damping: self.damping)
                .ignoresSafeArea()
        case let .mesh(colors):
            GreetMeshBackground(
                colors: colors,
                base: self.settlesIntoGroupedSurface ? Tokens.groupedBackground : Tokens.background,
                tuning: GreetMeshTuning.standard(colorScheme: self.colorScheme).damped(by: self.damping))
                .ignoresSafeArea()
        }
    }
}

private struct GreetSoftGradientBackground: View {
    let tones: GreetGradientTones
    let colorScheme: ColorScheme
    let damping: GreetGradientDamping

    var body: some View {
        let tuning = GreetGradientVisualTuning
            .soft(colorScheme: self.colorScheme)
            .damped(by: self.damping)

        ZStack {
            self.tones.base

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(tuning.baseTintOpacity),
                    self.tones.secondary.opacity(tuning.baseTintOpacity * 0.7),
                    self.tones.accent.opacity(tuning.baseTintOpacity * 0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(tuning.primaryOpacity),
                    self.tones.secondary.opacity(tuning.secondaryOpacity),
                    self.tones.accent.opacity(tuning.accentOpacity),
                    self.tones.base.opacity(tuning.baseFadeOpacity),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.base.opacity(tuning.topVeilOpacity),
                    self.tones.base.opacity(tuning.bottomVeilOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
    }
}

struct GreetSoftGradientTuning {
    let baseTintOpacity: Double
    let primaryOpacity: Double
    let secondaryOpacity: Double
    let accentOpacity: Double
    let baseFadeOpacity: Double
    let topVeilOpacity: Double
    let bottomVeilOpacity: Double

    func damped(by damping: GreetGradientDamping) -> Self {
        Self(
            baseTintOpacity: damping.tint(self.baseTintOpacity),
            primaryOpacity: damping.tint(self.primaryOpacity),
            secondaryOpacity: damping.tint(self.secondaryOpacity),
            accentOpacity: damping.tint(self.accentOpacity),
            baseFadeOpacity: damping.veil(self.baseFadeOpacity),
            topVeilOpacity: damping.veil(self.topVeilOpacity),
            bottomVeilOpacity: damping.veil(self.bottomVeilOpacity))
    }
}

enum GreetGradientVisualTuning {
    static func soft(colorScheme: ColorScheme) -> GreetSoftGradientTuning {
        if colorScheme == .dark {
            return GreetSoftGradientTuning(
                baseTintOpacity: 0.20,
                primaryOpacity: 0.24,
                secondaryOpacity: 0.18,
                accentOpacity: 0.16,
                baseFadeOpacity: 0.54,
                topVeilOpacity: 0.08,
                bottomVeilOpacity: 0.42)
        }

        return GreetSoftGradientTuning(
            baseTintOpacity: 0.12,
            primaryOpacity: 0.18,
            secondaryOpacity: 0.12,
            accentOpacity: 0.10,
            baseFadeOpacity: 0.62,
            topVeilOpacity: 0.04,
            bottomVeilOpacity: 0.78)
    }
}

private struct GreetMeshBackground: View {
    let colors: GreetMeshColors
    let base: Color
    let tuning: GreetMeshTuning

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: GreetMeshTuning.points,
            colors: [
                self.wash(self.colors.leading, self.tuning.topStrength),
                self.wash(self.colors.center, self.tuning.topStrength),
                self.wash(self.colors.trailing, self.tuning.topStrength),
                self.wash(self.colors.center, self.tuning.middleStrength),
                self.wash(self.colors.trailing, self.tuning.middleStrength * 0.8),
                self.wash(self.colors.center, self.tuning.middleStrength),
                self.base, self.base, self.base,
            ])
    }

    /// Keeps `strength` of `color` over the opaque base.
    private func wash(_ color: Color, _ strength: Double) -> Color {
        color.mix(with: self.base, by: 1 - strength)
    }
}

/// How much of the mesh colours survives over the surface, row by row.
///
/// The top row carries the colours, the middle row a softer echo of them, and the bottom row is the
/// surface itself, so text and controls below the title sit on the plain platform colour. Dark mode
/// keeps more colour, because a dark surface swallows chroma faster.
struct GreetMeshTuning: Equatable {
    let topStrength: Double
    let middleStrength: Double

    /// Three rows of three. The middle row leans up and to the leading side, so the colour falls
    /// off unevenly instead of in a straight band.
    static let points: [SIMD2<Float>] = [
        SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
        SIMD2(0, 0.40), SIMD2(0.6, 0.34), SIMD2(1, 0.46),
        SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1),
    ]

    static func standard(colorScheme: ColorScheme) -> Self {
        colorScheme == .dark
            ? Self(topStrength: 0.42, middleStrength: 0.18)
            : Self(topStrength: 0.34, middleStrength: 0.14)
    }

    func damped(by damping: GreetGradientDamping) -> Self {
        Self(topStrength: damping.tint(self.topStrength), middleStrength: damping.tint(self.middleStrength))
    }
}
#endif
