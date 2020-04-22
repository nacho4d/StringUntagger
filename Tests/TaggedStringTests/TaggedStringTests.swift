import XCTest
@testable import TaggedString

final class TaggedStringTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TaggedString().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
