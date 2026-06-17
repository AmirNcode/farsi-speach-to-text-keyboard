//
//  SpikeKeyboardView.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

//import SwiftUI
//
//struct SpikeKeyboardView: View {
//    let insert: (String) -> Void
//    let deleteBackward: () -> Void
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Text("Spike keyboard").font(.caption)
//            HStack {
//                Button("a") { insert("a") }
//                Button("b") { insert("b") }
//                Button("space") { insert(" ") }
//                Button("⌫") { deleteBackward() }
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity)
//    }
//}


import SwiftUI

struct SpikeKeyboardView: View {
    let insert: (String) -> Void
    let deleteBackward: () -> Void

    @State private var status = "Pick a language, tap 🎤, speak, tap ■"
    @State private var language: KeyboardLanguage = .english
    @State private var isRecording = false

    private let recorder = AudioRecorder()
    private let client = TranscriptionClient()

    // One top-row key to prove the flick gesture (index 0 → "1"/"۱").
    private var flickLetter: String { language == .english ? "q" : "ض" }

    var body: some View {
        VStack(spacing: 10) {
            Text(status).font(.caption).lineLimit(2)

            Picker("", selection: $language) {
                Text("EN").tag(KeyboardLanguage.english)
                Text("FA").tag(KeyboardLanguage.farsi)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                // Flick key: tap = letter, swipe down = digit.
                Text(flickLetter)
                    .frame(width: 56, height: 44)
                    .background(Color.gray.opacity(0.25))
                    .cornerRadius(8)
                    .overlay(alignment: .topTrailing) {
                        Text(FlickDigits.digit(forIndex: 0, language: language) ?? "")
                            .font(.system(size: 10)).foregroundStyle(.secondary).padding(3)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { v in
                                if v.translation.height > 20 {
                                    insert(FlickDigits.digit(forIndex: 0, language: language) ?? "")
                                } else {
                                    insert(flickLetter)
                                }
                            }
                    )

                Button(" space ") { insert(" ") }
                Button("⌫") { deleteBackward() }

                Button(isRecording ? "■ Stop" : "🎤 Speak") {
                    isRecording ? stopAndTranscribe() : startRecording()
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func startRecording() {
        do {
            try recorder.start()
            isRecording = true
            status = "Recording… tap ■ to stop"
            // 60s hard cap (D15)
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                if isRecording { stopAndTranscribe() }
            }
        } catch {
            status = "Mic error: \(error.localizedDescription)"
        }
    }

    private func stopAndTranscribe() {
        guard isRecording else { return }
        isRecording = false
        status = "Transcribing…"
        guard let data = recorder.stop(), !data.isEmpty else { status = "No audio captured"; return }
        let hint = language == .farsi ? "fa" : "en"
        Task {
            do {
                let r = try await client.transcribe(audio: data, language: hint)
                await MainActor.run { insert(r.text); status = "Inserted (\(r.language))" }
            } catch {
                await MainActor.run { status = "Error: \(error)" }
            }
        }
    }
}
