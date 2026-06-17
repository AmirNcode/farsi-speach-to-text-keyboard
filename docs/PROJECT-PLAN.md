# Project Plan & Task Tracker

The single blueprint for the whole project. Use it to decide what to work on each session and to track progress. Keep it updated as tasks complete.

**Legend:** ✅ done · ⏳ in progress · ⬜ to do · 👤 needs the owner (Mac / accounts / device)

**How to use this to save on usage limits:** each *phase* below is a self-contained session of work. Start a session by picking the next unchecked phase, point Claude at its detailed plan file, finish it, check it off. Don't try to do multiple phases in one session — scope creep burns tokens.

---

## Phase 0 — Design & docs ✅
- [x] Brainstorm + lock all decisions (D1–D15)
- [x] Master spec — `docs/superpowers/specs/2026-06-16-farsi-voice-keyboard-v1-design.md`
- [x] Context docs set — `docs/README.md` and `docs/context/*`
- [x] Repo + `CLAUDE.md` + `.gitignore`

## Phase 1 — Backend transcription Worker ✅ (deploy = owner)
Plan: `docs/superpowers/plans/2026-06-16-backend-transcription-worker.md`
- [x] Scaffold + `json` helper
- [x] `GroqProvider` (Whisper large-v3)
- [x] Provider factory + `Env`
- [x] `/transcribe` handler (token + size validation)
- [x] Worker entry + routing (`/health`, `/transcribe`)
- [x] Opt-in real-Groq integration test + backend README
- [x] Clean typecheck + `npm run typecheck`
- [x] 👤 **Deploy** — **LIVE** at `https://farsi-voice-keyboard.hello-fe6.workers.dev` (Groq key + APP_TOKEN set; `/health`, 401/400/404 verified). Real Groq transcription proven later, in the iOS spike.

## Phase 2 — iOS Spike #1 (de-risk) ⏳ in progress — KEY FINDING
Plan: `docs/superpowers/plans/2026-06-17-ios-spike-keyboard.md`.
**Findings (2026-06-17):**
- ✅ KeyboardKit free core renders custom keyboard + inserts text (after fixing framework embedding: app target Embed & Sign, extension Do Not Embed).
- ✅ Flick-down digit gesture works (`q`→`1`, `ض`→`۱`).
- ✅ Backend `/transcribe` live.
- ❌ **Mic recording blocked inside the keyboard extension** (iOS platform limit — see decisions.md **D16**). Pivot: record in the **container app**, return text to the keyboard via pasteboard/App Group.
- ⬜ Next: prove transcription pipeline in the container app (record → Worker → Farsi text), then build the keyboard→app→keyboard bounce. Decide pasteboard (free) vs App Group (maybe needs $99 acct).
- [ ] Xcode project: container app + keyboard extension target + App Group
- [ ] Barebones keyboard records mic (validate Full Access works in extension)
- [ ] POST audio to the deployed Worker → insert returned text
- [ ] Confirm KeyboardKit free core renders a custom view + handles a flick gesture
- [ ] Resolve D14 (emoji): is the free emoji keyboard cheap to include? → in v1 or defer
- [ ] 👤 Build/run on a real iPhone; manual mic test
- _Depends on Phase 1 deploy (needs live Worker URL + APP_TOKEN)._

## Phase 3 — EN + FA layouts + flick-down numbers ⬜
Plan: _to be written after Phase 2._
- [ ] English QWERTY layout
- [ ] Standard Persian layout (RTL)
- [ ] Globe toggle EN ↔ FA
- [ ] Flick-down number mapping (digits match language) — unit-tested
- [ ] Number hints on top-row keys

## Phase 4 — Container app: onboarding + settings ⬜
Plan: _to be written after Phase 3._
- [ ] Onboarding: enable keyboard + enable Full Access (with the privacy note)
- [ ] Settings: default language, digit style — stored in App Group
- [ ] App ↔ extension settings read path

## Phase 5 — Polish ⬜
Plan: _to be written after Phase 4._
- [ ] Recording overlay (waveform + timer + Stop)
- [ ] Error states (offline / provider failure) inline
- [ ] Haptics / key feedback
- [ ] Emoji keyboard (if D14 = in)

## Phase 6 — Beta to friends & family ⬜
- [ ] 👤 Apple Developer Program ($99/yr)
- [ ] 👤 TestFlight build + invites
- [ ] Owner accuracy check on everyday Farsi phrases (definition of done)

---

## Future (post-v1, separate spec+plan cycles each)
- [ ] Android keyboard (reuse layouts + same backend)
- [ ] Accounts + freemium/subscription (enforced in the Worker)
- [ ] Autocorrect + word prediction (Farsi)
- [ ] Custom themes
- [ ] Code-switching (mixed Farsi/English in one utterance)
- [ ] Streaming/live dictation
- [ ] Self-hosted private Whisper provider (privacy-sensitive users)

See `docs/context/roadmap.md` for rationale.
