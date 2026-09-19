#if os(iOS) || os(macOS)
import Testing
@testable import GreetKit

@Suite("Greet route state")
struct GreetRouteStateTests {
    private let routes = [
        GreetPrimaryRoute(id: "permissions"),
        GreetPrimaryRoute(id: "sample-data"),
        GreetPrimaryRoute(id: "notifications"),
    ]

    @Test
    func loadingBlocksAdvanceAndFailedCompletionKeepsTheFinalRouteForRetry() {
        var state = GreetRouteState(activeRouteID: self.routes[0].id)
        state.advance(after: 0, in: self.routes, isLoading: true)
        #expect(state.activeRouteID == self.routes[0].id)
        state.advance(after: 0, in: self.routes)
        #expect(state.activeRouteID == self.routes[1].id)
        state.advance(after: 1, in: self.routes)

        state.complete(isLoading: true)
        #expect(state.activeRouteID == self.routes.last?.id)
        state.complete(hasError: true)
        #expect(state.activeRouteID == self.routes.last?.id)
        state.complete()
        #expect(state.activeRouteID == nil)
    }

    @Test
    func startsOnTheOverview() {
        let state = GreetRouteState()

        #expect(state.activeRouteID == nil)
        #expect(state.phaseID(in: self.routes) == "overview")
        #expect(state.activeRoute(in: self.routes) == nil)
    }

    @Test
    func backRevisitsEarlierStepsAndReturnsToOverviewWithoutAdvancingWhileBusy() {
        var state = GreetRouteState(activeRouteID: self.routes[1].id)
        state.retreat(in: self.routes, isLoading: true)
        #expect(state.activeRouteID == self.routes[1].id)
        state.retreat(in: self.routes)
        #expect(state.activeRouteID == self.routes[0].id)
        #expect(state.transitionDirection == .backward)
        state.retreat(in: self.routes)
        #expect(state.activeRouteID == nil)
        state.retreat(in: self.routes)
        #expect(state.activeRouteID == nil)
    }

    @Test
    func beginOpensTheFirstRouteOfAChain() {
        var state = GreetRouteState()

        state.begin(routes: self.routes, hasRouteDestination: true)

        #expect(state.activeRouteID == "permissions")
        #expect(state.transitionDirection == .forward)
        #expect(state.phaseID(in: self.routes) == "route-permissions")
    }

    @Test
    func beginStaysOnTheOverviewWithoutARouteDestination() {
        var state = GreetRouteState()

        state.begin(routes: self.routes, hasRouteDestination: false)

        #expect(state.activeRouteID == nil)
        #expect(state.phaseID(in: self.routes) == "overview")
    }

    @Test
    func advanceMovesToTheNextRoute() {
        var state = GreetRouteState()
        state.begin(routes: self.routes, hasRouteDestination: true)

        state.advance(after: 0, in: self.routes)

        #expect(state.activeRouteID == "sample-data")
        #expect(state.transitionDirection == .forward)

        state.advance(after: 1, in: self.routes)

        #expect(state.activeRouteID == "notifications")
    }

    @Test
    func advancingPastTheLastRouteReturnsToTheOverview() {
        var state = GreetRouteState()
        state.begin(routes: self.routes, hasRouteDestination: true)

        state.advance(after: self.routes.count - 1, in: self.routes)

        #expect(state.activeRouteID == nil)
        #expect(state.transitionDirection == .backward)
        #expect(state.phaseID(in: self.routes) == "overview")
    }

    @Test
    func completeReturnsToTheOverviewAndReversesTheTransition() {
        var state = GreetRouteState()
        state.begin(routes: self.routes, hasRouteDestination: true)

        state.complete()

        #expect(state.activeRouteID == nil)
        #expect(state.transitionDirection == .backward)
    }

    @Test
    func activeRouteResolvesIndexAndRoute() {
        var state = GreetRouteState()
        state.begin(routes: self.routes, hasRouteDestination: true)
        state.advance(after: 0, in: self.routes)

        let activeRoute = state.activeRoute(in: self.routes)

        #expect(activeRoute?.index == 1)
        #expect(activeRoute?.route.id == "sample-data")
    }

    /// A consumer can compute `primaryRoutes`, so the list can change while a route is open.
    /// The state must resolve against the current list rather than trust the stored id.
    @Test
    func activeRouteIsNilWhenTheRouteIsNoLongerInTheList() {
        let state = GreetRouteState(activeRouteID: "removed-route")

        #expect(state.activeRoute(in: self.routes) == nil)
    }

    @Test
    func phaseIDFallsBackToTheOverviewWhenTheActiveRouteDisappears() {
        let state = GreetRouteState(activeRouteID: "removed-route")

        #expect(state.phaseID(in: self.routes) == "overview")
    }

    @Test
    func advanceHandlesASingleRouteChain() {
        let singleRoute = [GreetPrimaryRoute(id: "only")]
        var state = GreetRouteState()
        state.begin(routes: singleRoute, hasRouteDestination: true)

        #expect(state.activeRouteID == "only")

        state.advance(after: 0, in: singleRoute)

        #expect(state.activeRouteID == nil)
        #expect(state.transitionDirection == .backward)
    }

    @Test
    func reopeningAChainAfterCompletionRestoresForwardMotion() {
        var state = GreetRouteState()
        state.begin(routes: self.routes, hasRouteDestination: true)
        state.complete()

        #expect(state.transitionDirection == .backward)

        state.begin(routes: self.routes, hasRouteDestination: true)

        #expect(state.transitionDirection == .forward)
        #expect(state.activeRouteID == "permissions")
    }
}
#endif
