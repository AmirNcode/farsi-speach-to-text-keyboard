# iOS Spike #1 — Keyboard Records → Transcribes → Inserts

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (or subagent-driven-development). Steps use `- [ ]` checkboxes.
>
> **Environment note:** This plan is executed on the **owner's Mac in Xcode**. The AI assistant cannot run Xcode, sign builds, or drive an iPhone. Steps marked **👤** are owner actions; the AI writes the code and the exact click-path. A spike expects iteration — if KeyboardKit Swift needs a small tweak to compile (it's v10.4.1), adjust and continue; the goal is proof, not polish.

**Goal:** Prove the three riskiest assumptions in one barebones keyboard: (1) the keyboard extension can capture the **mic** with Full Access, (2) it can **POST audio to our live Worker and insert the returned text**, and (3) **KeyboardKit's free core** renders a custom keyboard and handles a **flick-down** gesture. Also resolve D14 (is emoji cheap?).

**Architecture:** A SwiftUI container app (requests mic permission) + a keyboard extension subclassing KeyboardKit's `KeyboardInputViewController`, rendering a minimal custom view (mic button, status line, a few keys, one flick key, EN/FA toggle). Recording via `AVAudioRecorder` (m4a, 16kHz mono). Upload via `URLSession` multipart to `https://farsi-voice-keyboard.hello-fe6.workers.dev/transcribe`.

**Tech Stack:** Swift, SwiftUI, KeyboardKit 10.4.1 (free core), AVFoundation, URLSession. Unit tests via XCTest.

**Working dir:** `/Users/amir/Workspace/FarsiVoiceKeyboard/ios`

**Scope guard:** This is the SPIKE, not the real keyboard. No full layouts, no settings, no App Group yet (those are Phases 3–4). Keep it minimal.

---

## Concrete identifiers (use these as-is)
- App bundle id: `com.farsivoicekeyboard.app`
- Keyboard extension bundle id: `com.farsivoicekeyboard.app.keyboard`
- Worker URL: `https://farsi-voice-keyboard.hello-fe6.workers.dev`
- APP_TOKEN: the value you saved during backend deploy — **paste it into `Config.swift`; never commit it.**

## File structure (locked)
```
ios/
  FarsiVoiceKeyboard.xcodeproj
  FarsiVoiceKeyboard/                 # app target
    FarsiVoiceKeyboardApp.swift
    ContentView.swift
    Info.plist                        # NSMicrophoneUsageDescription
  Keyboard/                           # keyboard extension target
    KeyboardViewController.swift
    SpikeKeyboardView.swift
    Info.plist                        # RequestsOpenAccess = YES
  Shared/                             # added to BOTH targets' membership
    Config.example.swift              # committed (placeholders)
    Config.swift                      # gitignored (real URL + token)
    FlickDigits.swift
    TranscriptionClient.swift
    AudioRecorder.swift
  FarsiVoiceKeyboardTests/            # unit tests (app target)
    FlickDigitsTests.swift
    TranscriptionClientTests.swift
```

---

### Task 1: Create the Xcode project + keyboard extension target  👤

- [ ] **Step 1: New project.** Xcode → File → New → Project → iOS → **App**. Product Name `FarsiVoiceKeyboard`, Interface **SwiftUI**, Language **Swift**, Organization identifier `com.farsivoicekeyboard` (so bundle id becomes `com.farsivoicekeyboard.app` — set Product Name/identifier so the bundle id matches `com.farsivoicekeyboard.app`; if Xcode makes it `com.farsivoicekeyboard.FarsiVoiceKeyboard`, that's fine too — just keep it consistent everywhere). Save it inside `/Users/amir/Workspace/FarsiVoiceKeyboard/ios` (create the `ios` folder).

- [ ] **Step 2: Add the keyboard extension target.** File → New → Target → iOS → **Custom Keyboard Extension**. Product Name: `Keyboard`. Activate the scheme if asked. This creates the `Keyboard/` folder with a `KeyboardViewController.swift`.

- [ ] **Step 3: Set signing.** Select the project → for **both** targets (FarsiVoiceKeyboard, Keyboard): Signing & Capabilities → Team = your personal Apple ID team (free). Let Xcode auto-manage signing.

- [ ] **Step 4: Verify it runs.** 👤 Plug in your iPhone, select it as the run destination, Run. The app launches (blank). This confirms the toolchain + signing work before we add anything.

- [ ] **Step 5: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): scaffold app + keyboard extension targets"
```

---

### Task 2: Add KeyboardKit and render a custom view

- [ ] **Step 1: Add the package.** 👤 Xcode → File → Add Package Dependencies → URL `https://github.com/KeyboardKit/KeyboardKit.git` → Dependency Rule "Up to Next Major" from `10.4.1`. When asked which target to add it to, add **KeyboardKit** to the **Keyboard** extension target (it needs it for the controller). Add it to the app target too if Xcode offers (harmless).

- [ ] **Step 2: Replace `Keyboard/KeyboardViewController.swift`** with a KeyboardKit subclass that renders our custom view:
```swift
import KeyboardKit
import SwiftUI

class KeyboardViewController: KeyboardInputViewController {

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] _ in
            SpikeKeyboardView(
                insert: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                deleteBackward: { [weak self] in
                    self?.textDocumentProxy.deleteBackward()
                }
            )
        }
    }
}
```
> If `viewWillSetupKeyboardView`/`setupKeyboardView` don't resolve for the installed version, use Xcode autocomplete on the `KeyboardInputViewController` instance to find the equivalent "setup keyboard view" override — the concept (return a SwiftUI view) is the same. This check is part of the spike.

- [ ] **Step 3: Create `Keyboard/SpikeKeyboardView.swift`** (a temporary placeholder so it compiles; real UI in Task 7):
```swift
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
```

- [ ] **Step 4: Verify on device.** 👤 Run the app once (installs the extension). Then: iPhone Settings → General → Keyboard → Keyboards → Add New Keyboard → **Keyboard** (FarsiVoiceKeyboard). Open Notes, tap 🌐 to switch to it. You should see "Spike keyboard" with a/b/space/⌫ buttons that type into Notes. **This proves KeyboardKit free core renders a custom view and can insert text.**

- [ ] **Step 5: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): KeyboardKit subclass renders custom view + inserts text"
```

---

### Task 3: Flick→digit mapping (TDD)

**Files:** Create `ios/Shared/FlickDigits.swift`, Test `ios/FarsiVoiceKeyboardTests/FlickDigitsTests.swift`

- [ ] **Step 1: Write the failing test** — `FlickDigitsTests.swift`
```swift
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
```

- [ ] **Step 2: Run to verify it fails.** 👤 Cmd+U (or Product → Test). Expected: compile error / `FlickDigits` unresolved.

- [ ] **Step 3: Implement** — `ios/Shared/FlickDigits.swift` (add to **both** targets' membership: File Inspector → Target Membership → check FarsiVoiceKeyboard + Keyboard)
```swift
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
```

- [ ] **Step 4: Run to verify it passes.** 👤 Cmd+U. Expected: 3 tests green.

- [ ] **Step 5: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): flick-to-digit mapping (EN/FA) with tests"
```

---

### Task 4: TranscriptionClient + multipart builder (TDD)

**Files:** Create `ios/Shared/TranscriptionClient.swift`, Test `ios/FarsiVoiceKeyboardTests/TranscriptionClientTests.swift`

- [ ] **Step 1: Write the failing test** (pure multipart-body checks + JSON decode — no network) — `TranscriptionClientTests.swift`
```swift
import XCTest
@testable import FarsiVoiceKeyboard

final class TranscriptionClientTests: XCTestCase {
    func testMultipartIncludesAudioAndLanguage() {
        let body = TranscriptionClient.multipartBody(
            audio: Data("AUDIO".utf8), language: "fa", boundary: "B"
        )
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
            audio: Data("X".utf8), language: nil, boundary: "B"
        )
        XCTAssertFalse(String(decoding: body, as: UTF8.self).contains("name=\"language\""))
    }
    func testDecodesResult() throws {
        let json = Data(#"{"text":"سلام","language":"fa"}"#.utf8)
        let r = try JSONDecoder().decode(TranscriptionResult.self, from: json)
        XCTAssertEqual(r.text, "سلام")
        XCTAssertEqual(r.language, "fa")
    }
}
```

- [ ] **Step 2: Run to verify it fails.** 👤 Cmd+U. Expected: `TranscriptionClient`/`TranscriptionResult` unresolved.

- [ ] **Step 3: Implement** — `ios/Shared/TranscriptionClient.swift` (add to **both** targets)
```swift
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
```

- [ ] **Step 4: Run to verify it passes.** 👤 Cmd+U. Expected: green.

- [ ] **Step 5: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): transcription client + multipart builder with tests"
```

---

### Task 5: Config files (real values stay out of git)

**Files:** Create `ios/Shared/Config.example.swift` (committed) and `ios/Shared/Config.swift` (gitignored).

- [ ] **Step 1: Add the gitignore rule.** Append to `/Users/amir/Workspace/FarsiVoiceKeyboard/.gitignore`:
```
# iOS local secrets
ios/**/Config.swift
```

- [ ] **Step 2: Create `ios/Shared/Config.example.swift`** (committed, placeholders) — add to both targets:
```swift
// Copy this file to Config.swift (same folder) and fill in real values.
// Config.swift is gitignored — never commit the token.
enum Config {
    static let workerURL = "https://farsi-voice-keyboard.hello-fe6.workers.dev"
    static let appToken = "PASTE_YOUR_APP_TOKEN_HERE"
}
```

- [ ] **Step 3: Create `ios/Shared/Config.swift`** 👤 (NOT committed) — add to both targets. Paste your real saved APP_TOKEN:
```swift
enum Config {
    static let workerURL = "https://farsi-voice-keyboard.hello-fe6.workers.dev"
    static let appToken = "<<your saved APP_TOKEN>>"
}
```
> Both files define `enum Config`. Keep only ONE in the build — since `Config.swift` is what you fill in, **remove `Config.example.swift` from Target Membership** (uncheck both targets in the File Inspector) so it's a reference doc only and doesn't cause a duplicate-symbol error.

- [ ] **Step 4: Commit (example only; Config.swift is ignored).**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add .gitignore ios/Shared/Config.example.swift
git commit -m "feat(ios): config scaffold (real token gitignored)"
```

---

### Task 6: AudioRecorder (m4a, 16kHz mono)

**Files:** Create `ios/Shared/AudioRecorder.swift` (add to both targets).

- [ ] **Step 1: Implement** — `ios/Shared/AudioRecorder.swift`
```swift
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
```

- [ ] **Step 2: Build to verify it compiles.** 👤 Cmd+B. Expected: build succeeds. (Real mic behavior is tested in Task 9 on device.)

- [ ] **Step 3: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): AVAudioRecorder wrapper (m4a 16kHz mono)"
```

---

### Task 7: Wire the spike keyboard UI (mic → record → transcribe → insert, + flick key + EN/FA toggle)

**Files:** Replace `ios/Keyboard/SpikeKeyboardView.swift`.

- [ ] **Step 1: Implement the real spike view** — `ios/Keyboard/SpikeKeyboardView.swift`
```swift
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
```

- [ ] **Step 2: Build.** 👤 Cmd+B. Fix any KeyboardKit/SwiftUI compile tweaks. Expected: build succeeds.

- [ ] **Step 3: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): spike keyboard UI — mic/record/transcribe/insert + flick + EN/FA"
```

---

### Task 8: Container app requests mic permission + onboarding text

**Files:** `ios/FarsiVoiceKeyboard/Info.plist`, `ios/FarsiVoiceKeyboard/ContentView.swift`, `ios/Keyboard/Info.plist`.

- [ ] **Step 1: App mic usage string.** 👤 In the **app** target Info (Signing target → Info, or Info.plist), add key **Privacy - Microphone Usage Description** (`NSMicrophoneUsageDescription`) = `Used for Farsi/English voice typing.`

- [ ] **Step 2: Request mic permission on launch** — replace `ios/FarsiVoiceKeyboard/ContentView.swift`:
```swift
import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var micStatus = "unknown"

    var body: some View {
        VStack(spacing: 16) {
            Text("Farsi Voice Keyboard — Spike").font(.headline)
            Text("Mic permission: \(micStatus)")
            Text("Setup:\n1) Settings → General → Keyboard → Keyboards → Add → Keyboard\n2) Tap it → enable Full Access\n3) In any app, tap 🌐 to switch, then 🎤 to dictate")
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
```
> If `AVAudioApplication.requestRecordPermission` is unavailable on the deployment target, use `AVAudioSession.sharedInstance().requestRecordPermission { granted in ... }`.

- [ ] **Step 3: Enable Full Access for the extension.** 👤 In the **Keyboard** target's `Info.plist`, under `NSExtension` → `NSExtensionAttributes`, set **`RequestsOpenAccess` = YES** (Boolean). (Xcode's keyboard template includes the `NSExtension` block; just flip `RequestsOpenAccess` to YES.)

- [ ] **Step 4: Build.** 👤 Cmd+B succeeds.

- [ ] **Step 5: Commit.**
```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add ios
git commit -m "feat(ios): mic permission request + onboarding + Full Access flag"
```

---

### Task 9: Device test + resolve risks  👤

Run on a real iPhone (Simulator can't prove mic/Full Access).

- [ ] **Step 1: Install + permit.** Run the app on your iPhone. Tap "Request microphone permission" → Allow. Then Settings → General → Keyboard → Keyboards → Add `Keyboard` → tap it → **Allow Full Access**.

- [ ] **Step 2: English dictation.** Open Notes → 🌐 to our keyboard → set **EN** → 🎤 → say "hello world this is a test" → ■. Within ~1–2s the text should appear. Record the result + the status line.

- [ ] **Step 3: Farsi dictation.** Set **FA** → 🎤 → say a Farsi sentence → ■. Confirm accurate Farsi text inserts. (This is the first real Groq call — uses your free quota.)

- [ ] **Step 4: Flick gesture.** Tap the `q`/`ض` key → letter inserts. Swipe down on it → `1`/`۱` inserts. Confirms KeyboardKit gesture handling.

- [ ] **Step 5: Error path.** Turn on Airplane Mode → 🎤 → speak → ■ → status shows an error (not a crash), nothing inserted.

- [ ] **Step 6: Resolve D14 (emoji).** Spend ≤30 min trying KeyboardKit's built-in emoji keyboard from the extension. Decide: trivial → include in v1; non-trivial → defer to v1.1. Write the decision into `docs/context/decisions.md` (D14) and `docs/PROJECT-PLAN.md`.

- [ ] **Step 7: Write findings.** Append a short "Spike #1 results" section to this file: did mic-in-extension work? Farsi accuracy impression? KeyboardKit free core verdict (stay on A, or fall back to from-scratch B)? Any blockers for Phase 3. Commit + push.

---

## If the mic does NOT work in the extension (the main risk)
Likely fixes, in order:
1. Confirm **Full Access** is ON and the app was granted mic permission first (Task 8/9).
2. Ensure `AVAudioSession` category is `.record` (or `.playAndRecord`) and `setActive(true)` succeeds (log the thrown error).
3. If still blocked: **fallback design** — move recording into the container app and hand off via a deep link / App Group file, with the keyboard polling for the result. Document this as a Phase-2 finding; it changes Phase 5 polish but not the backend.

## Self-review (done)
- Covers spike goals: mic (Tasks 6/9), POST+insert (Tasks 4/7/9), KeyboardKit render+flick (Tasks 2/7/9), D14 (Task 9.6). Maps to spec build-order step 2.
- TDD on the two pure-logic units (FlickDigits, multipart). Device-only behavior has an explicit manual plan.
- No secrets committed (Config.swift gitignored; token pasted locally).
