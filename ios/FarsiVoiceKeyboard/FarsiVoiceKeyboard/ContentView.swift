//
//  ContentView.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}


import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var micStatus = "unknown"

    var body: some View {
        VStack(spacing: 16) {
            Text("Farsi Voice Keyboard — Spike").font(.headline)
            Text("Mic permission: \(micStatus)")
            Text("Setup:\n1) Settings → General → Keyboard → Keyboards → Add → FarsiVoiceKeyboard\n2) Tap it → enable Full Access\n3) In any app, tap 🌐 to switch, then 🎤 to dictate")
                .font(.footnote).multilineTextAlignment(.leading)
            Button("Request microphone permission") { requestMic() }
        }
        .padding()
        .onAppear(perform: requestMic)
    }

    private func requestMic() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async { micStatus = granted ? "granted" : "denied" }
        }
    }
}
