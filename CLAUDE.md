# CLAUDE.md — Working Agreements

Instructions for any AI assistant (or developer) working in this repo.

## First thing: read the docs
**Always read [docs/README.md](docs/README.md) before doing anything.** It links the master spec and all context. The spec at `docs/superpowers/specs/2026-06-16-farsi-voice-keyboard-v1-design.md` is the source of truth.

## What this project is
An iOS custom keyboard for Farsi speakers. Headline feature: **accurate Farsi voice-to-text** via Whisper large-v3 (cloud). Secondary: **flick-down numbers** (iPad-style). Currently for the owner + friends/family; paid later.

## Stack
- iOS: Swift + SwiftUI + **KeyboardKit free/open-source core** (NOT Pro).
- Backend: **Cloudflare Worker** (TypeScript) → **Groq** `whisper-large-v3` (provider-swappable).

## How to work here
- **Owner is non-technical.** Recommend, don't interrogate. Default to sensible choices and explain plainly. Write any owner-facing step assuming no dev knowledge.
- **Use skills.** Brainstorming → writing-plans → executing-plans; TDD for logic; frontend-design for keyboard UI; Context7 for library/API docs (KeyboardKit, Groq, Cloudflare, Swift); Cloudflare MCP for Worker docs. If a needed skill isn't available, tell the owner.
- **TDD** for pure logic (flick→digit mapping, audio params, request building, Worker validation). See `docs/context/testing.md`.
- **Respect the constraints** in `docs/context/architecture.md`: full custom keyboard, ~60MB extension memory (no on-device models), Full Access for mic+network.
- **Keep the provider swappable** and the Worker as the future chokepoint for auth/limits/billing — don't bake the provider key into the app.

## Environment boundaries
- The AI assistant **cannot** run Xcode, build/sign iOS, drive an iPhone, or grant Full Access. Those run on the **owner's Mac/iPhone** — write the code + exact instructions; the owner executes. See `docs/context/setup-prerequisites.md`.
- The owner has **no Apple Developer account ($99/yr) yet** — only needed to distribute to other people's phones (TestFlight/App Store).

## Secrets
- Never commit secrets. `GROQ_API_KEY` and `APP_TOKEN` live as Cloudflare Worker secrets (see `docs/context/backend.md`). `.dev.vars`/`.env` are gitignored.

## Build order (v1)
1. Backend Worker + Groq round-trip (sample-audio tests).
2. iOS Spike #1: barebones keyboard records mic → POSTs → inserts (proves mic/Full Access + KeyboardKit free core; resolves emoji decision D14).
3. EN + FA layouts + flick-down numbers.
4. Container app onboarding + settings (App Group).
5. Polish (recording overlay, errors, haptics, emoji if D14 = in).
