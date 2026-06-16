# Architecture

## High-level
Three pieces: the **keyboard extension**, the **container app**, and a **Cloudflare Worker** backend. The keyboard records audio and sends it to the Worker; the Worker forwards it to a Whisper provider (Groq) and returns text.

```
┌─────────────────────────── iPhone ───────────────────────────┐
│   Container App (SwiftUI)            Keyboard Extension        │
│   • onboarding (enable kb,           • EN + FA layouts (RTL)   │
│     enable Full Access)              • flick-down numbers      │
│   • settings (digit style,           • mic key → record       │
│     default language)                • POST audio → backend    │
│                                      • insert returned text    │
│           └────────── App Group (shared settings) ──────────┘ │
└───────────────────────────────┬───────────────────────────────┘
                                 │ HTTPS POST /transcribe
                                 │ audio (m4a, 16kHz mono, ≤60s) + language hint + app token
                                 ▼
                  Cloudflare Worker (free tier)
                  • validate app token · enforce size
                  • GROQ_API_KEY as Worker secret
                  • TranscriptionProvider abstraction
                                 │
                                 ▼
                  Groq  whisper-large-v3  →  { text, language }
```

## Data flow (voice)
1. User taps mic in the keyboard → `AVAudioEngine`/recorder captures mic (needs Full Access).
2. Stop (or 60s cap) → encode to m4a, 16kHz mono.
3. `POST /transcribe` to the Worker with `language` hint (= active layout) and `X-App-Token`.
4. Worker validates, forwards to the selected provider (Groq), receives `{text, language}`.
5. Worker returns JSON; keyboard inserts `text` at the cursor via the text document proxy.
6. Errors surface inline; user retries.

## Why these boundaries
- **App ↔ Extension** are separate processes (iOS requirement). They share only settings via an **App Group**. The extension stays lean (memory budget).
- **App never holds the provider key.** Only the Worker does. The app holds a low-value `APP_TOKEN` (replaced by real auth later).
- **Provider behind an interface.** Groq today; Cloudflare Workers AI or self-hosted later — backend-only swap, no app release.

## Memory & platform constraints
- Keyboard extension ≈ 60MB ceiling → no on-device models; cloud transcription only.
- Mic + networking require **Full Access** (`RequestsOpenAccess = YES`).
- Mic-in-extension is historically finicky on iOS (Gboard/SwiftKey do it) → proven in Spike #1 before further build.

## Tech choices
- **iOS:** Swift + SwiftUI, **KeyboardKit free/open-source core** for keyboard plumbing (see `decisions.md` D13).
- **Backend:** TypeScript on **Cloudflare Workers** (Wrangler), tested with Vitest + Miniflare.
- **Transcription:** **Groq** hosted `whisper-large-v3` (OpenAI-compatible `/audio/transcriptions`).

## Future-proofing already baked in
- Worker is the chokepoint for future **accounts / free-minute limits / subscription**.
- Provider abstraction enables a **self-hosted private** Whisper later for privacy-sensitive users.
- Layout engine is data-driven, so **Android** can reuse the same EN/FA layout definitions and the same backend.
