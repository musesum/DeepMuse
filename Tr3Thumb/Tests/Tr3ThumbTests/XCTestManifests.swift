import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Tr3ThumbTests.allTests),
    ]
}
#endif
