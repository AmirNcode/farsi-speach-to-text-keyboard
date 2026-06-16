# Farsi Voice Keyboard

A custom **iOS keyboard for Farsi speakers** whose headline feature is **accurate Farsi (and English) voice-to-text**, powered by OpenAI's open-source **Whisper large-v3** model running behind a low-cost backend. It also adds **iPad-style flick-down numbers** (tap a top-row key for the letter, flick down for the number).

> **Status:** design approved & locked; implementation planning next. See **[docs/](docs/README.md)**.

## What's here
- `docs/` — full project context (spec, decisions, architecture, setup, testing). **Read [docs/README.md](docs/README.md) first.**
- `ios/` — iOS app + keyboard extension *(created during implementation)*.
- `backend/` — Cloudflare Worker transcription proxy *(created during implementation)*.

## Stack
- **iOS:** Swift + SwiftUI, KeyboardKit (free/open-source core).
- **Backend:** Cloudflare Worker (TypeScript) → Groq `whisper-large-v3` (provider-swappable).

## v1 scope
English + Farsi (RTL) layouts · flick-down numbers · voice-to-text (tap mic → speak → Stop → insert) · onboarding + settings. Free / near-zero cost for friends & family.

See **[docs/context/roadmap.md](docs/context/roadmap.md)** for what's deferred (Android, accounts/billing, autocorrect, emoji-if-not-in-v1, …).
