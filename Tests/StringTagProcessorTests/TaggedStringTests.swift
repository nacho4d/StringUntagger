import XCTest
#if os(iOS)
import UIKit
#else
import AppKit
#endif

@testable import StringTagProcessor

let font17 = Font.systemFont(ofSize: 17)
let font17b = Font.boldSystemFont(ofSize: 17)
let font12 = Font.systemFont(ofSize: 12)

final class StringTagProcessorTests: XCTestCase {
    
    
    func testSimplest() {
        var callsNum = 0 // To test attributter block is called the right number of times
    
        /// Simplest case
        /// Just tag the parts you want to customize. All other parts will be enclosed in a implicit tag called "root".
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "click <i>here</i> please") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
            // attributes for all elements
            case "root": return [ .foregroundColor: Color.gray, .font: font17]
            // attributes for b tag. Inner elements inherit outter elements attributes so only pass the ones that need override
            case "i": return [ .font: font17b]
            default: return [:]
            }
        }
        
        XCTAssertEqual(res.string, "click here please")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(0, 6))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17b], range: NSMakeRange(6, 4))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(10, 7))
        XCTAssertEqual(callsNum, 2)
    }
    
    func testSimple() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        /// Simple case
        /// This is also OK. Still the entire string will be enclosed in an implicit tag called "root".
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "<mytag>content</mytag>") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
            case "root": return [:]
            case "mytag": return [ .foregroundColor: Color.red, .font: font17]
            default: return [:]
            }
        }
        
        XCTAssertEqual(res.string, "content")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(0, 7))
        XCTAssertEqual(callsNum, 2)
    }
    
    func testSimpleWithVariousConsecutiveTags() {
        var callsNum = 0 // To test attributter block is called the right number of times
      
        /// Common case
        /// String has three consecutive tags plus the implicit "root" tag, the block will be called various times.
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "<morning>huevo-frito </morning><lunch>fired-egg</lunch><dinner> a めやままき with rice</dinner>") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
            case "root": return [.foregroundColor: Color.magenta, .font: font17b]
            case "morning": return [ .foregroundColor: Color.red, .font: font17]
            case "lunch": return [ .foregroundColor: Color.blue, .font: font12]
            case "dinner": return [:] // No overrides for dinner tag means ALL attributes from outter elements will be used
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "huevo-frito fired-egg a めやままき with rice")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(0, 12))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font12], range: NSMakeRange(12, 9))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.magenta, .font: font17b], range: NSMakeRange(21, 18))
        XCTAssertEqual(callsNum, 4)
    }
    
    func testOneInsideOfOther() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "<outter>start<inner>this is the middle</inner>end</outter>") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
            case "root": return [:] // Setting something here would be useful since there is nothing that is in 'root' that is not in 'outter'
            case "outter": return [ .foregroundColor: Color.red, .font: font17]
            case "inner": return [ .foregroundColor: Color.blue]
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "startthis is the middleend")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(0, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font17], range: NSMakeRange(5, 18))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(23, 3))
        XCTAssertEqual(callsNum, 3)
    }
    
    func testMalformed() {
        /// Mal formed strings cannot be parsed and they are returned as unparsed and no attributed NSAttributedString. See logs.
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "<inner>malformed</outter>") { (tagName) -> [NSAttributedString.Key : Any] in
            switch tagName {
            case "outter": return [ .foregroundColor: Color.red, .font: font17]
            case "inner": return [ .foregroundColor: Color.blue]
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "<inner>malformed</outter>")
        XCTAssertNoAttributesAtRange(res, range: NSMakeRange(0, 25))
    }
    
    func testCustomRootName() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        /// If default "root" is not good for your needs, you can set the root name in the initializer
        /// Example, you have `start<root>the middle</root>end` and you want to `the middle` part to have different attributes then you should set root element other name.
        let tsp = StringTagProcessor(rootName: "MyCustomRootName")
        let res = tsp.attributedString(from: "start<root>this is the middle</root>end") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
                // This is the custom initializer
            case "MyCustomRootName": return [ .foregroundColor: Color.lightGray, .font: font12]
                // This a tag that would clash with MyCustomRootName
            case "root": return [ .foregroundColor: Color.blue]
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "startthis is the middleend")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.lightGray, .font: font12], range: NSMakeRange(0, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font12], range: NSMakeRange(5, 18))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.lightGray, .font: font12], range: NSMakeRange(23, 3))
        XCTAssertEqual(callsNum, 2)
    }
    
    func testResetAttributes() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        /// If you want to erase attributes for a certain attributed for a certain tag you can pass NSNull()
        let tsp = StringTagProcessor()
        let res = tsp.attributedString(from: "<outter>start<inner>this <really-inner>is</really-inner> the middle</inner>end</outter>") { (tagName) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
            case "root": return [ .foregroundColor: Color.green, .font: font12]
            case "outter": return [ .foregroundColor: Color.red, .font: font17]
            case "inner": return [ .foregroundColor: Color.blue]
            case "really-inner": return [ .font: NSNull()] // Remove font attribute and set value from root
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "startthis is the middleend")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(0, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font17], range: NSMakeRange(5, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font12], range: NSMakeRange(10, 2))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font17], range: NSMakeRange(12, 11))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(23, 3))
        XCTAssertEqual(callsNum, 4)
    }

    static var allTests = [
        ("testSimplest", testSimplest),
        ("testSimple", testSimple),
        ("testSimpleWithVariousConsecutiveTags", testSimpleWithVariousConsecutiveTags),
        ("testOneInsideOfOther", testOneInsideOfOther),
        ("testMalformed", testMalformed),
        ("testCustomRootName", testCustomRootName),
        ("testResetAttributes", testResetAttributes),
    ]
}
