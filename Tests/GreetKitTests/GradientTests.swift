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
}
#endif
