import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct OnboardingTests {
    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "terrariumidle.onboarding.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    @Test func storagePersistsAndResetsCompletion() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(OnboardingStorage.hasCompleted(in: defaults) == false)

        OnboardingStorage.markCompleted(in: defaults)
        #expect(OnboardingStorage.hasCompleted(in: defaults) == true)

        OnboardingStorage.reset(in: defaults)
        #expect(OnboardingStorage.hasCompleted(in: defaults) == false)
    }

    @Test func postSplashRouteShowsOnboardingOnlyBeforeCompletion() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(OnboardingStorage.postSplashRoute(isAuthenticated: false, in: defaults) == .onboardingView)
        #expect(OnboardingStorage.postSplashRoute(isAuthenticated: true, in: defaults) == .onboardingView)

        OnboardingStorage.markCompleted(in: defaults)

        #expect(OnboardingStorage.postSplashRoute(isAuthenticated: false, in: defaults) == .loginView(id: ""))
        #expect(OnboardingStorage.postSplashRoute(isAuthenticated: true, in: defaults) == .homeView)
    }

    @Test func postOnboardingRouteRespectsAuthenticationState() {
        #expect(OnboardingStorage.postOnboardingRoute(isAuthenticated: false) == .loginView(id: ""))
        #expect(OnboardingStorage.postOnboardingRoute(isAuthenticated: true) == .homeView)
    }

    @Test func onboardingStepsHaveExpectedOrderAndNonEmptyContent() {
        let steps = OnboardingStep.allCases
        #expect(steps == [.welcome, .care, .gardenMenu, .relax])

        for step in steps {
            #expect(!step.eyebrow.isEmpty)
            #expect(!step.title.isEmpty)
            #expect(!step.summary.isEmpty)
            #expect(!step.highlights.isEmpty)
        }
    }
}
