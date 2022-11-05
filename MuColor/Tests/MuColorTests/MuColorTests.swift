import XCTest
@testable import MuColor

final class MuColorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MuColor().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
