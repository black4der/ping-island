import XCTest
@testable import Ping_Island

@MainActor
private final class AccessibilityStatusProbe {
    var isTrusted = false

    func currentStatus() -> Bool {
        isTrusted
    }
}

final class SettingsPanelViewModelTests: XCTestCase {
    private func makeDefaults(testName: String = #function) -> UserDefaults {
        let suiteName = "PingIslandTests.SettingsPanelViewModel.\(testName).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testQoderCLINoticeGateIsConsumedOnlyOnce() {
        let defaults = makeDefaults()
        let firstGate = QoderCLIHookRefreshNoticeGate(defaults: defaults)

        XCTAssertTrue(firstGate.consumeShouldShowNotice())
        XCTAssertFalse(firstGate.consumeShouldShowNotice())

        let secondGate = QoderCLIHookRefreshNoticeGate(defaults: defaults)

        XCTAssertFalse(secondGate.consumeShouldShowNotice())
    }

    func testRefreshAccessibilityStatusUsesLatestProviderValue() async {
        await MainActor.run {
            let defaults = makeDefaults()
            let probe = AccessibilityStatusProbe()
            let viewModel = SettingsPanelViewModel(
                qoderCLIHookRefreshStatusProvider: { nil },
                qoderCLIHookRefreshNoticeDefaults: defaults,
                accessibilityStatusProvider: { probe.currentStatus() }
            )

            viewModel.refreshAccessibilityStatus()
            XCTAssertFalse(viewModel.accessibilityEnabled)

            probe.isTrusted = true
            viewModel.refreshAccessibilityStatus()

            XCTAssertTrue(viewModel.accessibilityEnabled)
        }
    }
}
