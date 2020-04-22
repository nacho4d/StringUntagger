//
//  File.swift
//  
//
//  Created by Guillermo Ignacio Enriquez Gutierrez on 2020/04/23.
//

import XCTest
#if os(iOS)
import UIKit
typealias Font = UIFont
typealias Color = UIColor
#else
import AppKit
typealias Font = NSFont
typealias Color = NSColor
#endif

func XCTAssertAttributesAtRange(_ target: NSAttributedString, attrs expectedAttrs: [NSAttributedString.Key : Any], range expectedRange: NSRange, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    expectedAttrs.forEach { (expectedKey, expectedValue) in
        var range: NSRange = NSRange(location: NSNotFound, length: 0)
        let value = target.attribute(expectedKey, at: expectedRange.location, effectiveRange: &range)
        
        // Convert range to string because I am interested in a perfect match. Location ok, length:not-ok is useless and correct message would be cumbersome
        XCTAssertEqual(NSStringFromRange(range), NSStringFromRange(expectedRange), message() + " Invalid range of key: \(expectedKey)", file: file, line: line)
        
        // `Any` type cannot be Asserted so it needs to be casted to a more concrete type.
        // Would be nice to be able to cast to Equatable ?!
        if let v = expectedValue as? Color {
            XCTAssertEqual(value as? Color, v, "\(message()) Invalid value of key: \(expectedKey) at range:\(range)", file: file, line: line)
        } else if let v = expectedValue as? CGFloat {
            XCTAssertEqual(value as? CGFloat, v, "\(message()) Invalid value of key: \(expectedKey) at range:\(range)", file: file, line: line)
        } else if let v = expectedValue as? Font {
            XCTAssertEqual(value as? Font, v, "\(message()) Invalid value of key: \(expectedKey) at range:\(range)", file: file, line: line)
        } else {
            XCTFail("Please define a new type to compare here :) ")
        }
    }
}

func XCTAssertNoAttributesAtRange(_ target: NSAttributedString, range expectedRange: NSRange, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    var range: NSRange = NSRange(location: NSNotFound, length: 0)
    let values = target.attributes(at: expectedRange.location, effectiveRange: &range)
    XCTAssertTrue(values.isEmpty, file: file, line: line)
}
