//
//  AudioRecorder.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

import AVFoundation

final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    /// Begin recording to a temp m4a file. Throws if the session/recorder can't start.
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rec-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let r = try AVAudioRecorder(url: url, settings: settings)
        guard r.record() else { throw NSError(domain: "AudioRecorder", code: 1) }
        recorder = r
        fileURL = url
    }

    /// Stop and return the recorded bytes (or nil).
    func stop() -> Data? {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        guard let url = fileURL else { return nil }
        defer { try? FileManager.default.removeItem(at: url) }
        return try? Data(contentsOf: url)
    }
}
