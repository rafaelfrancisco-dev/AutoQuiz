//
//  AutoQuizUITests.swift
//  AutoQuizUITests
//
//  Created by Rafael Francisco on 10/06/2025.
//

import XCTest

final class AutoQuizUITests: XCTestCase {
    private let sampleDocumentID = "11111111-1111-1111-1111-111111111111"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsRootSplitView() throws {
        let app = launchApp()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.outlines["document-list"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["add-item"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testSelectingDocumentShowsDetailScreen() throws {
        let app = launchApp()

        openSeedDocument(in: app)

        XCTAssertTrue(app.otherElements["document-start-screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start Quiz"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDocumentModalRoutesPresentAndDismissCleanly() throws {
        let app = launchApp()
        openSeedDocument(in: app)

        app.buttons["Start Quiz"].click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Quiz Options"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()
        XCTAssertTrue(app.otherElements["document-start-screen"].waitForExistence(timeout: 5))

        app.buttons["Ask Document"].click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ask a Question"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()

        app.buttons["View Analytics"].click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Accuracy Trend"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()

        app.buttons["Spaced Repetition"].click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Spaced Repetition"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()

        openDocumentMenuItem("Question History", in: app)
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()

        openDocumentMenuItem("Add Content", in: app)
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add Content"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()

        XCTAssertTrue(app.otherElements["document-start-screen"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments += ["UITEST_SAMPLE_DATA", "-ApplePersistenceIgnoreState", "YES"]
            app.launch()
        }
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SAMPLE_DATA", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        ensureMainWindow(in: app)
        return app
    }

    @MainActor
    private func openSeedDocument(in app: XCUIApplication) {
        let row = app.staticTexts["document-row-\(sampleDocumentID)"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        row.click()
    }

    @MainActor
    private func ensureMainWindow(in app: XCUIApplication) {
        if app.windows.firstMatch.waitForExistence(timeout: 3) {
            return
        }

        let fileMenu = app.menuBars.menuBarItems["File"].firstMatch
        XCTAssertTrue(fileMenu.waitForExistence(timeout: 5))
        fileMenu.click()

        let newWindow = app.menuItems["New Window"].firstMatch
        XCTAssertTrue(newWindow.waitForExistence(timeout: 5))
        newWindow.click()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    private func openDocumentMenuItem(_ title: String, in app: XCUIApplication) {
        let menuButton = app.menuButtons["document-actions-menu"].firstMatch
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.click()

        let menuItem = app.menuItems[title].firstMatch
        XCTAssertTrue(menuItem.waitForExistence(timeout: 5))
        menuItem.click()
    }
}
