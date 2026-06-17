//
//  TranscriptionClient.swift
//  FarsiVoiceKeyboard
//
//  Created by Amir Noorafkan on 2026-06-17.
//

import Foundation

struct TranscriptionResult: Decodable {
    let text: String
    let language: String
}

enum TranscriptionError: Error { case badURL, http(Int), badResponse }

struct TranscriptionClient {
    var workerURL: String = Config.workerURL
    var appToken: String = Config.appToken
    var session: URLSession = .shared

    func transcribe(audio: Data, language: String?) async throws -> TranscriptionResult {
        guard let url = URL(string: workerURL + "/transcribe") else { throw TranscriptionError.badURL }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = Self.multipartBody(audio: audio, language: language, boundary: boundary)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw TranscriptionError.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw TranscriptionError.http(http.statusCode) }
        return try JSONDecoder().decode(TranscriptionResult.self, from: data)
    }

    static func multipartBody(audio: Data, language: String?, boundary: String) -> Data {
        var body = Data()
        func add(_ s: String) { body.append(Data(s.utf8)) }
        if let language {
            add("--\(boundary)\r\n")
            add("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            add("\(language)\r\n")
        }
        add("--\(boundary)\r\n")
        add("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n")
        add("Content-Type: audio/m4a\r\n\r\n")
        body.append(audio)
        add("\r\n--\(boundary)--\r\n")
        return body
    }
}
