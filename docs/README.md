# Docs Index

Start here. These docs contain everything needed for a developer or AI assistant to pick up this project cold.

## Read in this order
0. **[PROJECT-PLAN.md](PROJECT-PLAN.md)** — phased task tracker; what's done, what's next, one-phase-per-session.
1. **[context/overview.md](context/overview.md)** — what this is, why, current phase, key constraints.
2. **[superpowers/specs/2026-06-16-farsi-voice-keyboard-v1-design.md](superpowers/specs/2026-06-16-farsi-voice-keyboard-v1-design.md)** — the master v1 spec (the source of truth).
3. **[context/decisions.md](context/decisions.md)** — every locked decision + the reasoning (D1–D15).
4. **[context/architecture.md](context/architecture.md)** — components, data flow, boundaries.
5. **[context/ios-keyboard.md](context/ios-keyboard.md)** — iOS specifics: targets, KeyboardKit, layouts, flick numbers, voice capture.
6. **[context/backend.md](context/backend.md)** — Cloudflare Worker, `/transcribe` API contract, provider abstraction.
7. **[context/setup-prerequisites.md](context/setup-prerequisites.md)** — accounts, keys, Xcode, enabling the keyboard (non-technical steps).
8. **[context/testing.md](context/testing.md)** — automated tests + the manual on-device test plan.
9. **[context/roadmap.md](context/roadmap.md)** — v1 scope and everything deferred.
10. **[context/glossary.md](context/glossary.md)** — terms (Farsi, Whisper, KeyboardKit, Full Access, …).

## TL;DR for an AI assistant resuming work
- **Project:** an iOS custom keyboard for Farsi speakers; headline feature = accurate Farsi **voice-to-text** via Whisper large-v3 (cloud). Secondary feature = **flick-down numbers** (iPad-style).
- **Stack:** Swift + SwiftUI + **KeyboardKit free core**; backend = **Cloudflare Worker** (TypeScript) → **Groq** `whisper-large-v3` (provider-swappable).
- **Phase:** design **approved & locked**. Next artifact is the implementation plan, then build in order: backend → iOS voice spike → layouts → onboarding/settings → polish.
- **Hard constraints:** keyboard is a full custom replacement; ~60MB extension memory (no on-device models); mic+network need Full Access; owner is non-technical; owner has **no Apple Developer account yet** (needed only to distribute to others).
- **Build/run env:** iOS build/run/device-testing happens on the **owner's Mac/iPhone**, not in the AI's environment.
- See the root **[CLAUDE.md](../CLAUDE.md)** for working agreements.
