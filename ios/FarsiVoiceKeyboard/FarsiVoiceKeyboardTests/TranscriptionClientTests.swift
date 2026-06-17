//
//  TranscriptionClientTests.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

import XCTest
@testable import FarsiVoiceKeyboard

final class TranscriptionClientTests: XCTestCase {
    func testMultipartIncludesAudioAndLanguage() {
        let body = TranscriptionClient.multipartBody(
            audio: Data("AUDIO".utf8), language: "fa", boundary: "B")
        let s = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(s.contains("--B"))
        XCTAssertTrue(s.contains("name=\"audio\"; filename=\"audio.m4a\""))
        XCTAssertTrue(s.contains("name=\"language\""))
        XCTAssertTrue(s.contains("fa"))
        XCTAssertTrue(s.contains("AUDIO"))
        XCTAssertTrue(s.hasSuffix("--B--\r\n"))
    }
    func testMultipartOmitsLanguageWhenNil() {
        let body = TranscriptionClient.multipartBody(
            audio: Data("X".utf8), language: nil, boundary: "B")
        XCTAssertFalse(String(decoding: body, as: UTF8.self).contains("name=\"language\""))
    }
    func testDecodesResult() throws {
        let json = Data(#"{"text":"سلام","language":"fa"}"#.utf8)
        let r = try JSONDecoder().decode(TranscriptionResult.self, from: json)
        XCTAssertEqual(r.text, "سلام")
        XCTAssertEqual(r.language, "fa")
    }
}
