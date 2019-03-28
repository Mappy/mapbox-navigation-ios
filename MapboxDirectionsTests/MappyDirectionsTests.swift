import XCTest
@testable import MapboxDirections


class MappyDirectionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMappyErrorParsing() {
        let error: NSError? = nil
        var errorJson: [String: Any] = ["status": 400,
                                        "message": "No QID provided (None)"]
        var resultError = Directions.informativeMappyError(describing: errorJson, underlyingError: error)
        XCTAssertEqual(resultError.localizedFailureReason, "Status: 400 - message: No QID provided (None) - id: no id")
        
        errorJson = ["status": 502,
                     "message": "Could not find GPS initial route",
                     "id": "GPS:find_initial_route"]
        resultError = Directions.informativeMappyError(describing: errorJson, underlyingError: error)
        XCTAssertEqual(resultError.localizedFailureReason, "Status: 502 - message: Could not find GPS initial route - id: GPS:find_initial_route")
    }
    
}
