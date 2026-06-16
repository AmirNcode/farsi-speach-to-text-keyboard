# Farsi Voice Keyboard — v1 Design Spec

- **Status:** Approved (design phase complete)
- **Date:** 2026-06-16
- **Owner:** Amir
- **Scope of this spec:** iOS lean keyboard (English + Farsi layouts, flick-down numbers, voice-to-text) + a minimal transcription backend. This is **v1 only**. Android, accounts/billing, autocorrect, etc. are future cycles.

---

## 1. Product summary

A custom iOS keyboard for Farsi-speaking people whose headline feature is **accurate Farsi (and English) voice-to-text**. Existing keyboards do English dictation well but Farsi dictation poorly; this app closes that gap by running OpenAI's open-source **Whisper large-v3** model (via a low-cost hosted provider) behind a backend we control.

Beyond voice, it behaves like a normal keyboard, plus one ergonomics feature: **iPad-style flick-down numbers** on the top letter row (tap a key for the letter, flick down for the number) so you never switch to a separate numbers page for digits.

**Current phase:** personal use for the owner + friends and family. Cost must stay near-zero. Paid/subscription comes later once quality is proven.

## 2. Goals & non-goals

**Goals (v1):**
- Accurate Farsi voice-to-text; good English voice-to-text.
- English + Farsi (RTL) keyboard layouts with a language toggle.
- Flick-down numbers on the top row, digits matching the active language.
- Near-zero running cost at friends/family scale.
- A backend that can later grow accounts + subscriptions without an app rewrite.

**Non-goals (v1) — see roadmap:**
- Android (iOS first).
- Accounts, billing, subscription enforcement.
- Autocorrect, word prediction, custom themes.
- Mixed Farsi+English in a single spoken phrase (code-switching).
- Live streaming dictation.
- Preview/confirm step before inserting transcribed text.

## 3. Locked decisions (from brainstorming)

| # | Decision | Choice |
|---|---|---|
| D1 | Where transcription runs | **Cloud** via a backend proxy (on-device can't fit accurate Farsi in a keyboard's memory budget) |
| D2 | First platform | **iOS** |
| D3 | v1 size | **Lean** (layouts + flick numbers + voice; no autocorrect/predictions) |
| D4 | Monetization | **Freemium + subscription — LATER.** v1 is free/near-zero-cost for friends & family |
| D5 | Transcription model & host | Open-source **Whisper large-v3**, hosted on **Groq** (free dev tier) to start, **provider-swappable** |
| D6 | Backend shape | A **Cloudflare Worker** proxy we control; holds the provider key; the app never holds it |
| D7 | Dictation language selection | **Follow the active layout** (EN/FA) + Whisper **auto-detect** as a safety net |
| D8 | Code-switching | **Not in v1** (one language per dictation) |
| D9 | Number-row digits | **Match active language**: Western `1234567890` on EN, Persian `۱۲۳۴۵۶۷۸۹۰` on FA |
| D10 | Voice interaction | **Tap mic → speak → tap Stop → insert** (record-then-transcribe; most accurate) |
| D11 | Number gesture | **Flick down** on the key (iPad-style); tap = letter; small grey number hint on key |
| D12 | Result handling | **Insert directly at cursor** (no preview step) |
| D13 | Keyboard build approach | **KeyboardKit free/open-source core** + our own EN/FA layouts & voice; **NOT** Pro |
| D14 | Emoji | **In v1 if cheap** via KeyboardKit's free emoji keyboard; **auto-defer to v1.1** if it adds material scope (decided during de-risk spike) |
| D15 | Max clip length | **60 seconds** per dictation |

## 4. Architecture

```
┌─────────────────────────── iPhone ───────────────────────────┐
│                                                               │
│   Container App (SwiftUI)            Keyboard Extension        │
│   • onboarding:                      • EN + FA custom layouts  │
│     - enable keyboard                  (FA renders RTL)        │
│     - enable Full Access             • flick-down numbers      │
│   • settings:                        • mic key → record audio  │
│     - default digit style            • POST audio to backend   │
│     - default language               • insert returned text    │
│   • (optional) test-dictation        • emoji (if D14 = in)     │
│                                                               │
│           └────────── App Group (shared settings) ──────────┘ │
└───────────────────────────────┬───────────────────────────────┘
                                 │ HTTPS POST /transcribe
                                 │ body: audio (m4a, 16kHz mono, ≤60s)
                                 │ + language hint + app token header
                                 ▼
                  Cloudflare Worker  (free tier)
                  • validates app token
                  • holds GROQ_API_KEY as a Worker secret
                  • provider abstraction (Groq → CF AI → self-host)
                  • forwards audio + language hint
                                 │
                                 ▼
                  Groq: whisper-large-v3
                                 │
                                 ▼
                  returns { text, language }
```

### Components & responsibilities
- **Keyboard Extension** — renders layouts, handles taps + flick gestures, records the mic, talks to the backend, inserts text. Memory-constrained (~60MB); keeps no heavy models.
- **Container App** — onboarding + settings only in v1. Hosts the App Group for shared settings.
- **App Group** — shared `UserDefaults` suite so settings set in the app are read by the extension.
- **Cloudflare Worker** — the only network endpoint the app talks to. Keeps the provider key off the device, hints the language, and abstracts the provider so we can swap Groq → Cloudflare Workers AI → self-hosted Whisper without an app update.
- **Provider (Groq)** — runs Whisper large-v3 and returns text + detected language.

## 5. Keyboard UX detail

### Layouts
- **English:** standard QWERTY.
- **Farsi:** standard Persian layout, rendered right-to-left.
- **Toggle:** the globe/🌐 key cycles EN ↔ FA (long-press globe = system keyboard switch).

### Flick-down numbers
- **Tap** a top-row key → the letter. **Quick downward swipe (flick)** on it → the number.
- A small grey number hint sits on each top-row key (iPad style).
- Positional mapping of the 10 top-row keys:
  - EN: `Q W E R T Y U I O P` → `1 2 3 4 5 6 7 8 9 0`
  - FA: `ض ص ث ق ف غ ع ه خ ح` → `۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹ ۰`
- Digit style follows the active layout (D9), overridable in settings.

### Voice flow (D10, D12)
1. User taps the **mic key**.
2. Keyboard records (overlay shows a live waveform + elapsed timer + a **Stop** button). Hard cap **60s**.
3. User taps Stop (or hits the cap).
4. Audio is encoded (m4a, 16kHz mono) and POSTed to the Worker with the **language hint = active layout**.
5. ~1–2s later, the returned text is **inserted at the cursor**.
6. On error (offline / provider failure), show a small inline message ("No connection — try again"); nothing is silently dropped.

### Feedback
- Key-press feedback + haptics (KeyboardKit free-core feature).

## 6. Backend detail (Cloudflare Worker)

### Endpoint
`POST /transcribe`
- **Headers:** `X-App-Token: <shared secret>` (abuse deterrent for v1; not real auth)
- **Body:** `multipart/form-data` with:
  - `audio`: the clip (m4a/16kHz mono, ≤60s)
  - `language`: ISO-639-1 hint (`fa` or `en`), optional
- **Response 200:** `{ "text": "...", "language": "fa" }`
- **Errors:** `401` bad/missing app token · `413` clip too large · `502` provider failure · `400` malformed.

### Provider abstraction
A single `TranscriptionProvider` interface with one implementation now (`GroqProvider`) and a config flag to select it. Swapping to Cloudflare Workers AI (`@cf/openai/whisper-large-v3-turbo`) or a self-hosted endpoint is adding one file + flipping the flag — no app change.

### Secrets / config
- `GROQ_API_KEY` — Worker secret.
- `APP_TOKEN` — Worker secret, also embedded in the app build (v1 only; replaced by real auth later).
- `PROVIDER` — env var selecting the active provider.

## 7. Error handling & guardrails
- 60s clip cap enforced client-side **and** server-side (`413`).
- Network/provider errors surface inline; the user can retry. No offline fallback in v1 (Apple's built-in dictation is not available to third-party keyboards).
- Full Access is mandatory (mic + network); onboarding blocks voice until it's enabled and states plainly that audio is sent to the transcription service during recording.

## 8. Privacy
- Audio is sent to the backend and on to the provider (Groq) only while recording, only when the user taps the mic.
- No audio is stored by the app. The Worker does not persist audio (pass-through).
- Onboarding discloses this. (A self-hosted provider for a privacy-sensitive audience is a documented future option — D5/D6 make it a backend-only change.)

## 9. Testing strategy
- **Backend:** integration tests (Vitest + Miniflare/Wrangler) using sample **Farsi** and **English** clips → assert non-empty text and correct detected language; unit tests for the provider interface and token/size validation.
- **iOS:** unit tests for flick→digit mapping, audio encoding params, and the (mocked) network client. A **manual on-device test plan** covers mic capture + Full Access — the part the Simulator can't fully validate.
- TDD for logic units (mapping, encoding, request building) where practical.

## 10. Repo structure
```
/ios       Xcode project: App target + Keyboard extension target + shared App Group
/backend   Cloudflare Worker (Wrangler) + provider abstraction + tests
/docs      this spec + /context (deep-dive docs for future AI/devs)
```

## 11. Known risks & prerequisites
- 🔴 **Apple Developer Program ($99/yr)** is **required to put this on friends'/family's phones** (TestFlight/App Store). Build & test work without it (Simulator + free 7-day on-device provisioning), but distribution is gated. *Owner action when ready to share.*
- 🟠 **Mic capture inside a keyboard extension** is the riskiest iOS assumption → **Spike #1** must prove it before further build.
- 🟠 **KeyboardKit free core for RTL + flick callouts** — validated in the same spike; fallback is a from-scratch SwiftUI keyboard (approach B).
- 🟠 **Environment:** Xcode + a real iPhone are needed to build/run/device-test; these run on the owner's Mac, not in the AI's environment.

## 12. Build order
1. **Backend** Worker + Groq round-trip, proven with sample-audio integration tests.
2. **iOS Spike #1:** barebones keyboard that records the mic → POSTs to the Worker → inserts text. Proves mic/Full Access + KeyboardKit free core (+ emoji-effort check for D14).
3. **Layouts:** EN + FA + flick-down numbers.
4. **Container app:** onboarding + settings (App Group).
5. **Polish:** recording overlay, error states, haptics, (emoji if D14 = in).

## 13. Future (out of scope here)
Android keyboard · accounts + freemium/subscription · autocorrect & prediction · custom themes · code-switching · streaming dictation · on-device English fallback · self-hosted private provider. See `docs/context/roadmap.md`.
