//
//  FlickDigitsTests.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

import XCTest
@testable import FarsiVoiceKeyboard

final class FlickDigitsTests: XCTestCase {
    func testEnglishEnds() {
        XCTAssertEqual(FlickDigits.digit(forIndex: 0, language: .english), "1")
        XCTAssertEqual(FlickDigits.digit(forIndex: 9, language: .english), "0")
    }
    func testFarsiEnds() {
        XCTAssertEqual(FlickDigits.digit(forIndex: 0, language: .farsi), "۱")
        XCTAssertEqual(FlickDigits.digit(forIndex: 9, language: .farsi), "۰")
    }
    func testOutOfRangeIsNil() {
        XCTAssertNil(FlickDigits.digit(forIndex: 10, language: .english))
        XCTAssertNil(FlickDigits.digit(forIndex: -1, language: .farsi))
    }
}
