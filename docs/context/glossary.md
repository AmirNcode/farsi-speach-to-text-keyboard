# Glossary

- **Farsi / Persian** — the language (فارسی). Written **right-to-left (RTL)**. Uses Persian digits `۰۱۲۳۴۵۶۷۸۹` (distinct from Arabic-Indic and Western).
- **Whisper** — OpenAI's open-source speech-to-text model (MIT license). `large-v3` is the most accurate multilingual variant (good Persian). "tiny/base" are small but inaccurate for Farsi.
- **whisper.cpp** — a C++ port of Whisper for efficient local/self-hosted inference (e.g., on a Mac).
- **Groq** — an inference provider hosting Whisper via an OpenAI-compatible API; has a free dev tier. Our starting transcription provider.
- **Cloudflare Worker** — serverless function on Cloudflare's edge; our backend proxy. Free tier suffices for now.
- **Cloudflare Workers AI** — Cloudflare's hosted models incl. `@cf/openai/whisper-large-v3-turbo`; free daily allocation. Backup provider.
- **Keyboard extension** — on iOS, a custom keyboard is an app *extension*, a separate sandboxed process with a tight (~60MB) memory budget.
- **Container app** — the normal app that ships alongside the keyboard extension (handles onboarding/settings).
- **App Group** — a shared storage area letting the app and its extension share settings.
- **Full Access** — the iOS permission a keyboard needs for network + microphone (`RequestsOpenAccess`).
- **KeyboardKit** — a Swift/SwiftUI framework for custom keyboards. **Free core** (used here) vs **Pro** (paid: prebuilt locales, themes, autocomplete — not used).
- **Flick-down number** — iPad-style gesture: tap a top-row key = letter, quick downward swipe = number.
- **Code-switching** — mixing two languages in one utterance (e.g., Farsi + English). Out of scope for v1.
- **Text document proxy** — the iOS API a keyboard uses to insert/delete text in the host app's field.
- **TestFlight** — Apple's beta-distribution tool; needs the $99/yr Apple Developer Program.
- **Wrangler** — Cloudflare's CLI for developing/deploying Workers.
- **Provider abstraction** — our `TranscriptionProvider` interface so the Whisper host (Groq/Cloudflare/self-host) is swappable without app changes.
