//
//  Untitled.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

enum KeyboardLanguage { case english, farsi }

enum FlickDigits {
    static let westernDigits = ["1","2","3","4","5","6","7","8","9","0"]
    static let persianDigits = ["۱","۲","۳","۴","۵","۶","۷","۸","۹","۰"]

    /// Digit string for a top-row key position 0...9 in the given language, else nil.
    static func digit(forIndex index: Int, language: KeyboardLanguage) -> String? {
        guard (0..<10).contains(index) else { return nil }
        switch language {
        case .english: return westernDigits[index]
        case .farsi:   return persianDigits[index]
        }
    }
}
