#if os(iOS) || os(macOS)
import Foundation

enum GreetRouteTransitionDirection: Equatable {
    case forward
    case backward
}

/// Transient navigation state for the primary button flow.
///
/// Kept as a plain value type so the transitions stay testable without a hosted view.
/// Every accessor resolves against the caller's current routes, so a route list that
/// changes while a route is open cannot leave the state pointing at a route that is
/// no longer rendered.
struct GreetRouteState: Equatable {
    struct ActiveRoute: Equatable {
        let index: Int
        let route: GreetPrimaryRoute
    }

    private(set) var activeRouteID: GreetPrimaryRoute.ID?
    private(set) var transitionDirection: GreetRouteTransitionDirection

    init(
        activeRouteID: GreetPrimaryRoute.ID? = nil,
        transitionDirection: GreetRouteTransitionDirection = .forward)
    {
        self.activeRouteID = activeRouteID
        self.transitionDirection = transitionDirection
    }

    /// Opens the first route of the chain.
    ///
    /// With no destination builder or no routes, the state is left untouched so the overview stays
    /// on screen and the primary action is the caller's `onPrimary` alone.
    mutating func begin(routes: [GreetPrimaryRoute], hasRouteDestination: Bool) {
        guard hasRouteDestination, let firstRoute = routes.first else {
            return
        }

        self.transitionDirection = .forward
        self.activeRouteID = firstRoute.id
    }

    /// Moves to the route following `index`, completing the chain when there is no route left.
    mutating func advance(after index: Int, in routes: [GreetPrimaryRoute], isLoading: Bool = false) {
        guard !isLoading else { return }
        let nextIndex = index + 1

        guard routes.indices.contains(nextIndex) else {
            self.complete()
            return
        }

        self.transitionDirection = .forward
        self.activeRouteID = routes[nextIndex].id
    }

    /// Returns to the previous step, or to the overview from the first step.
    mutating func retreat(in routes: [GreetPrimaryRoute], isLoading: Bool = false) {
        guard !isLoading, let active = self.activeRoute(in: routes) else { return }
        self.transitionDirection = .backward
        self.activeRouteID = active.index == 0 ? nil : routes[active.index - 1].id
    }

    /// Returns to the overview unless the consumer is still completing setup or needs a retry.
    mutating func complete(isLoading: Bool = false, hasError: Bool = false) {
        guard !isLoading, !hasError else { return }
        self.transitionDirection = .backward
        self.activeRouteID = nil
    }

    /// The route currently on screen, or `nil` when the active id is not part of `routes`.
    func activeRoute(in routes: [GreetPrimaryRoute]) -> ActiveRoute? {
        guard let activeRouteID = self.activeRouteID else {
            return nil
        }

        guard let index = routes.firstIndex(where: { $0.id == activeRouteID }) else {
            return nil
        }

        return ActiveRoute(index: index, route: routes[index])
    }

    /// Identifies what is on screen so the container can key its transition animation.
    ///
    /// Resolved against `routes` rather than the raw active id, so the phase always matches
    /// the view that is actually rendered.
    func phaseID(in routes: [GreetPrimaryRoute]) -> String {
        guard let activeRoute = self.activeRoute(in: routes) else {
            return "overview"
        }

        return "route-\(activeRoute.route.id)"
    }
}
#endif
