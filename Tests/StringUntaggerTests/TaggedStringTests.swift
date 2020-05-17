
import XCTest
#if os(iOS)
import UIKit
#else
import AppKit
#endif
// There are defined here because all tests reuse this and I want to avoid long long lines of code
let font17 = Font.systemFont(ofSize: 17)
let font17b = Font.boldSystemFont(ofSize: 17)
let font18b = Font.boldSystemFont(ofSize: 18)
let font12 = Font.systemFont(ofSize: 12)

@testable import StringUntagger

final class StringUntaggerTests: XCTestCase {
    
    // MARK: - String Extension
    
    func testSimplest() {
        let res = "click <i>here</i> please".attributted(attributter: [
            "root": [ .foregroundColor: Color.gray, .font: font17],
            "i": [ .font: font17b]
        ])
        XCTAssertEqual(res.string, "click here please")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(0, 6))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17b], range: NSMakeRange(6, 4))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(10, 7))
    }
    
    // MARK: - Dictionary based APIs
     
    func testSimplest() {
        /// Simplest case
        /// Just tag the parts you want to customize. Outter parts will be enclosed in a implicit tag called "root".
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "click <i>here</i> please", attributer:[
                "root": [ .foregroundColor: Color.gray, .font: font17],
                "i": [ .font: font17b]
            ])
        XCTAssertEqual(res.string, "click here please")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(0, 6))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17b], range: NSMakeRange(6, 4))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(10, 7))
    }
    
    func testSimple() {
        /// Simple case
        /// This is also OK. Still the entire string will be enclosed in an implicit tag called "root".
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<mytag>content</mytag>", attributer: [
            "root": [:],
            "mytag": [ .foregroundColor: Color.red, .font: font17],
        ])
        XCTAssertEqual(res.string, "content")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.red, .font: font17], range: NSMakeRange(0, 7))
    }
    
    func testCustomRootName() {
        /// If default "root" is not good for your needs, you can set the root name in the initializer
        /// Example, you have `start<root>the middle</root>end` and you want to `the middle` part to have different attributes then you should set root element other name.
        let tsp = StringUntagger(rootName: "MyCustomRootName")
        let res = tsp.attributedString(from: "start<root>this is the middle</root>end", attributer: [
            // This is the custom root tag. Set so internal tag does not class
            "MyCustomRootName": [ .foregroundColor: Color.lightGray, .font: font12],
            // This a tag that would clash with default 'root' and would be hard to differentiate between tags. Thanks to 'MyCustomRootName' now it is fine :)
            "root": [ .foregroundColor: Color.blue],
        ])

        XCTAssertEqual(res.string, "startthis is the middleend")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.lightGray, .font: font12], range: NSMakeRange(0, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.blue, .font: font12], range: NSMakeRange(5, 18))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.lightGray, .font: font12], range: NSMakeRange(23, 3))
    }
    
    // MARK: - Block base APIs
    
    func testSimplest_withBlock() {
        var callsNum = 0 // To test attributter block is called the right number of times
    
        /// Simplest case
        /// Just tag the parts you want to customize. All other parts will be enclosed in a implicit tag called "root".
        /// Block base API offers `parentTags` which should give full control for attributes that need to be set dynamically.
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "click <i>here</i> and <b><i>here</i> too</b> please") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
            callsNum += 1
            switch tagName {
                // base attributes
                case "root": return [ .foregroundColor: Color.gray, .font: font17]
                // attributes for b tag. Inner elements inherit outter elements attributes so only pass the ones that need override
                case "i":
                    // parentTags contains an array of parents. From the outter most to the inner most order.
                    if parentTags.joined(separator: ".") == "root.b.i" {
                        return [ .font: font18b]
                    } else {
                        return [ .font: font17b]
                    }
                    
                // attributes for b tag.
                case "b": return [ .font: font17b, .underlineStyle: NSUnderlineStyle.double]
                default: return [:]
            }
        }
        
        XCTAssertEqual(res.string, "click here and here too please")
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(0, 6))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17b], range: NSMakeRange(6, 4))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(10, 5))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font18b, .underlineStyle: NSUnderlineStyle.double], range: NSMakeRange(15, 4))
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17b, .underlineStyle: NSUnderlineStyle.double], range: NSMakeRange(19, 4))
        
        XCTAssertAttributesAtRange(res, attrs: [ .foregroundColor: Color.gray, .font: font17], range: NSMakeRange(23, 7))
        XCTAssertEqual(callsNum, 4)
    }
    
    func testSimple_withBlock() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        /// Simple case
        /// This is also OK. Still the entire string will be enclosed in an implicit tag called "root".
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<mytag>content</mytag>") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
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
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<morning>huevo-frito </morning><lunch>fired-egg</lunch><dinner> a めやままき with rice</dinner>") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
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
        
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<outter>start<inner>this is the middle</inner>end</outter>") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
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
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<inner>malformed</outter>") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
            switch tagName {
            case "outter": return [ .foregroundColor: Color.red, .font: font17]
            case "inner": return [ .foregroundColor: Color.blue]
            default: return [:]
            }
        }

        XCTAssertEqual(res.string, "<inner>malformed</outter>")
        XCTAssertNoAttributesAtRange(res, range: NSMakeRange(0, 25))
    }
    
    func testCustomRootName_withBlock() {
        var callsNum = 0 // To test attributter block is called the right number of times
        
        /// If default "root" is not good for your needs, you can set the root name in the initializer
        /// Example, you have `start<root>the middle</root>end` and you want to `the middle` part to have different attributes then you should set root element other name.
        let tsp = StringUntagger(rootName: "MyCustomRootName")
        let res = tsp.attributedString(from: "start<root>this is the middle</root>end") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
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
        let tsp = StringUntagger()
        let res = tsp.attributedString(from: "<outter>start<inner>this <really-inner>is</really-inner> the middle</inner>end</outter>") { (tagName, parentTags) -> [NSAttributedString.Key : Any] in
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
