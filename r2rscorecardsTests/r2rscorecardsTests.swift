//
//  r2rscorecardsTests.swift
//  r2rscorecardsTests
//
//  Minimal unit test stub. Add more tests here as the app grows.
//

import XCTest
@testable import r2rscorecards

final class r2rscorecardsTests: XCTestCase {

    // MARK: - Stub (always passes; confirms test target runs)

    func testRuns() {
        XCTAssertTrue(true, "Test target runs successfully.")
    }

    // MARK: - BoxingRules (pure logic, no dependencies)

    func testBoxingRules_validRoundScore_10_9_returnsTrue() {
        XCTAssertTrue(BoxingRules.isValidRoundScore(red: 10, blue: 9))
    }

    func testBoxingRules_invalidRoundScore_5_5_returnsFalse() {
        XCTAssertFalse(BoxingRules.isValidRoundScore(red: 5, blue: 5))
    }
}
