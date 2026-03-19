import XCTest
@testable import Z_Paste

final class AppDelegateInteractionTests: XCTestCase {
    func testOutsideClickDoesNotHideWindowWhileContextMenuIsPresented() {
        let appDelegate = AppDelegate()
        appDelegate.setContextMenuPresentedForTesting(true)

        XCTAssertFalse(appDelegate.shouldHideForOutsideClick(eventIsInsidePanel: false))
    }

    func testOutsideClickStillHidesWindowWhenContextMenuIsNotPresented() {
        let appDelegate = AppDelegate()
        appDelegate.setContextMenuPresentedForTesting(false)

        XCTAssertTrue(appDelegate.shouldHideForOutsideClick(eventIsInsidePanel: false))
        XCTAssertFalse(appDelegate.shouldHideForOutsideClick(eventIsInsidePanel: true))
    }
}
