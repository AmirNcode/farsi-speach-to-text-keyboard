//
//  SpikeKeyboardView.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

import SwiftUI

struct SpikeKeyboardView: View {
    let insert: (String) -> Void
    let deleteBackward: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Spike keyboard").font(.caption)
            HStack {
                Button("a") { insert("a") }
                Button("b") { insert("b") }
                Button("space") { insert(" ") }
                Button("⌫") { deleteBackward() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
