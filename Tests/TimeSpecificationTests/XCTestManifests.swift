#if !canImport(ObjectiveC)
import XCTest

extension TimeSpecificationTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TimeSpecificationTests = [
        ("test_codable", test_codable),
        ("test_comparison", test_comparison),
        ("test_date", test_date),
        ("test_description", test_description),
        ("test_floatLiteral", test_floatLiteral),
        ("test_integerLiteral", test_integerLiteral),
        ("test_normalization", test_normalization),
        ("test_sumAndDifference", test_sumAndDifference),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TimeSpecificationTests.__allTests__TimeSpecificationTests),
    ]
}
#endif
