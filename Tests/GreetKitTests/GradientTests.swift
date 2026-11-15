#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

@Suite("Gradient backgrounds")
struct GradientTests {
    @Test
    func dampingIsActiveForEitherAccessibilitySetting() {
        #expect(!GreetGradientDamping(reduceTransparency: false, increaseContrast: false).isActive)
        #expect(GreetGradientDamping(reduceTransparency: true, increaseContrast: false).isActive)
        #expect(GreetGradientDamping(reduceTransparency: false, increaseContrast: true).isActive)
    }

    /// Both settings mean the same thing for a decorative wash: less colour, more of the opaque
    /// base, so foreground contrast stops depending on where the colour happens to sit.
    @Test
    func softGradientDampsItsWashWhenAFlatBackgroundIsPreferred() {
        let standard = GreetGradientVisualTuning.soft(colorScheme: .light)
        let damped = standard.damped(by: GreetGradientDamping(
            reduceTransparency: true,
            increaseContrast: false))

        #expect(damped.primaryOpacity < standard.primaryOpacity)
        #expect(damped.secondaryOpacity < standard.secondaryOpacity)
        #expect(damped.accentOpacity < standard.accentOpacity)
        #expect(damped.baseTintOpacity < standard.baseTintOpacity)
        #expect(damped.topVeilOpacity > standard.topVeilOpacity)
        #expect(damped.bottomVeilOpacity > standard.bottomVeilOpacity)
        #expect(damped.bottomVeilOpacity <= 1)
    }

    @Test
    func tuningIsUntouchedWhenDampingIsInactive() {
        let soft = GreetGradientVisualTuning.soft(colorScheme: .light)

        #expect(soft.damped(by: .none).primaryOpacity == soft.primaryOpacity)
    }

    @Test
    func tonesAreDeeperInDarkModeThanInLight() {
        let light = GreetGradientTones(brand: .indigo, colorScheme: .light)
        let dark = GreetGradientTones(brand: .indigo, colorScheme: .dark)

        #expect(light.primary == .indigo)
        #expect(dark.primary == .indigo)
        #expect(light.secondary != dark.secondary)
        #expect(light.accent != dark.accent)
    }

    /// Supporting tones used to be fixed hues — `.cyan` and `.mint` regardless of brand — so the
    /// field read as three unrelated colours. They are now washed from the brand itself.
    @Test
    func supportingTonesAreDerivedFromTheBrand() {
        let red = GreetGradientTones(brand: .red, colorScheme: .light)
        let blue = GreetGradientTones(brand: .blue, colorScheme: .light)

        #expect(red.secondary != blue.secondary)
        #expect(red.accent != blue.accent)
        #expect(red.secondary != Color.cyan)
        #expect(red.accent != Color.mint)
    }

    @Test
    func meshKeepsItsColoursInOrderAndDefaultsToCyanBlueAndIndigo() {
        let given = Self.meshColors(.mesh(leading: .red, center: .green, trailing: .orange))
        let standard = Self.meshColors(.mesh)

        #expect(given?.leading == .red)
        #expect(given?.center == .green)
        #expect(given?.trailing == .orange)
        #expect(standard?.leading == .cyan)
        #expect(standard?.center == .blue)
        #expect(standard?.trailing == .indigo)
    }

    @Test
    func meshKeepsMoreColourInDarkModeThanInLight() {
        let light = GreetMeshTuning.standard(colorScheme: .light)
        let dark = GreetMeshTuning.standard(colorScheme: .dark)

        #expect(dark.topStrength > light.topStrength)
        #expect(dark.middleStrength > light.middleStrength)
        #expect(light.middleStrength < light.topStrength)
    }

    /// The same rule as the soft gradient: either setting damps the colour, so text below the
    /// title never depends on where the colour sits.
    @Test
    func meshDampsItsColourWhenAFlatBackgroundIsPreferred() {
        let standard = GreetMeshTuning.standard(colorScheme: .light)
        let damped = standard.damped(by: GreetGradientDamping(reduceTransparency: false, increaseContrast: true))

        #expect(damped.topStrength < standard.topStrength)
        #expect(damped.middleStrength < standard.middleStrength)
        #expect(standard.damped(by: .none) == standard)
    }

    /// The mesh is drawn edge to edge, so its outer points have to sit on the edges, and the bottom
    /// row is the surface itself.
    @Test
    func meshPointsSpanTheWholeSurface() {
        let points = GreetMeshTuning.points

        #expect(points.count == 9)
        #expect(points[0...2].allSatisfy { $0.y == 0 })
        #expect(points[6...8].allSatisfy { $0.y == 1 })
        #expect([points[0], points[3], points[6]].allSatisfy { $0.x == 0 })
        #expect([points[2], points[5], points[8]].allSatisfy { $0.x == 1 })
    }

    #if os(macOS)
        /// Hosting runs the body, which construction alone does not, on both surfaces the mesh
        /// settles into.
        @Test
        @MainActor
        func meshDrawsOnTheWelcomeAndOnAPage() {
            for grouped in [false, true] {
                let host = NSHostingView(rootView: GreetBackgroundView(
                    background: .mesh,
                    settlesIntoGroupedSurface: grouped)
                    .frame(width: 200, height: 300))
                host.layoutSubtreeIfNeeded()

                #expect(host.fittingSize == CGSize(width: 200, height: 300))
            }
        }
    #endif

    private static func meshColors(_ background: GreetBackground) -> GreetMeshColors? {
        guard case let .mesh(colors) = background.storage else { return nil }
        return colors
    }
}
#endif
