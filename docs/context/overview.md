# Overview — Farsi Voice Keyboard

## What this is
A custom **iOS keyboard** for Farsi speakers. The headline feature is **accurate Farsi voice-to-text** (English too). It otherwise works like a normal keyboard, plus **iPad-style flick-down numbers** on the top row.

## Why it exists
English dictation on existing keyboards is good; **Farsi dictation is not**. No keyboard does Farsi voice-to-text well. We close that gap using OpenAI's open-source **Whisper large-v3** model, hosted cheaply behind a backend we control.

## Who it's for (now)
The owner (Amir) + friends and family. **Not yet a commercial product.** Cost must stay near-zero. It becomes a paid app later, once Farsi quality is proven.

## The two differentiating features
1. **Farsi voice-to-text** that's actually accurate (Whisper large-v3 via cloud).
2. **Flick-down numbers**: tap a top-row key for the letter, flick down for the number — no switching to a numbers page.

## Current phase
Design is **approved and locked**. Next: implementation plan, then build in this order — backend → iOS voice spike → layouts → onboarding/settings → polish.

## Key constraints to always remember
- A third-party keyboard on iOS is a **full custom replacement** — you can't add to Apple's keyboard.
- Keyboard extensions have a **tight (~60MB) memory budget** — no heavy on-device models; transcription is cloud.
- The mic + network need **Full Access** enabled by the user.
- Owner is **non-technical** — favor clear recommendations and sensible defaults; write instructions assuming no prior iOS/dev knowledge.
- Owner does **not yet have an Apple Developer account** ($99/yr) — needed only to distribute to other people's phones.

## Where to read more
- The master spec: `docs/superpowers/specs/2026-06-16-farsi-voice-keyboard-v1-design.md`
- Decisions + rationale: `docs/context/decisions.md`
- Architecture: `docs/context/architecture.md`
- iOS specifics: `docs/context/ios-keyboard.md`
- Backend: `docs/context/backend.md`
- Setup/prereqs: `docs/context/setup-prerequisites.md`
- Testing: `docs/context/testing.md`
- Roadmap: `docs/context/roadmap.md`
- Glossary: `docs/context/glossary.md`
