# Decisions & Rationale (ADR-style)

Every decision locked during brainstorming, with the reasoning, so a future AI/dev knows *why* — not just *what*.

### D1 — Transcription runs in the cloud, not on-device
Accurate Farsi needs Whisper **large-v3**. A keyboard extension's ~60MB memory budget only fits "tiny" Whisper, whose Farsi accuracy is poor. So transcription runs server-side; the keyboard records and uploads audio.

### D2 — iOS first
Owner is on a Mac; iOS has the hardest constraints (mic-in-extension), so doing it first de-risks the whole idea. Android is more permissive and comes later.

### D3 — Lean v1
v1 = EN+FA layouts, flick-down numbers, voice-to-text. No autocorrect/prediction. Focus the build on the two differentiators, not on re-creating a full IME's bells and whistles.

### D4 — Freemium + subscription, but LATER
Cloud transcription costs money at scale, so the long-term model is free minutes + paid unlimited. For now (friends/family) it's free/near-zero-cost; accounts + billing are deferred.

### D5 — Whisper large-v3 on Groq (free tier), provider-swappable
The Whisper **model** is open-source/MIT (free to run). The cost is only *where it runs*. Verified options:
- **Groq** — hosts `whisper-large-v3` (best Farsi accuracy) via an OpenAI-compatible API; **free dev tier**. Chosen to start.
- **Cloudflare Workers AI** — `whisper-large-v3-turbo`, 10,000 neurons/day free, then ~$0.0005/audio-min. Strong backup.
- **Self-hosted whisper.cpp** on the owner's Mac — $0 + fully private, but the Mac must stay on/reachable. Future privacy option.
Provider is abstracted so switching is a backend-only change.

### D6 — Backend is a Cloudflare Worker proxy we control
Calling Groq directly from the app would bake an extractable key into the binary and make limits/billing hard. A thin Worker keeps the key off the device, hints the language, abstracts the provider, and is the natural chokepoint for future accounts/limits/billing. Cloudflare's free tier covers friends/family volume.

### D7 — Dictation language follows the active layout, with auto-detect fallback
If the FA layout is active, we hint `fa`; if EN, we hint `en`. Whisper's auto-detect corrects it if the user actually spoke the other language. No extra taps, hard to get wrong.

### D8 — No code-switching in v1
Mixing Farsi + English in a single spoken phrase is unreliable in Whisper and adds risk. One dominant language per dictation; switch layout for the other.

### D9 — Number digits match the active language
Western `1234567890` on EN, Persian `۱۲۳۴۵۶۷۸۹۰` on FA — most natural for each. Overridable in settings.

### D10 — Tap mic → speak → tap Stop → insert (record-then-transcribe)
Whisper sees the full clip = best accuracy, simplest implementation, best fit for the proxy. ~1–2s after Stop. (Not hold-to-talk, not live streaming.)

### D11 — Flick-down number gesture (iPad-style)
Tap = letter, quick downward swipe = number, with a small grey number hint on each top-row key. Matches "how iPad has them." (Not long-press, not an always-visible number row.)

### D12 — Insert directly at the cursor
No preview/confirm step; transcribed text drops straight in like normal dictation. User edits inline if needed.

### D13 — KeyboardKit **free/open-source core**, not Pro
KeyboardKit's free core provides key rendering, the callout/gesture system (for flicks), the dynamic layout engine, feedback, and an emoji keyboard. Its **prebuilt Persian layout, themes, and autocomplete are Pro (paid)** — which conflicts with the near-zero-cost goal — so we define EN/FA layouts ourselves and use only the free core. Fallback if the free core can't do RTL+flicks cleanly: a from-scratch SwiftUI keyboard (approach B).

### D14 — Emoji: in v1 if cheap, else v1.1
KeyboardKit's free core includes an emoji keyboard, so it may be low-effort. Decision is finalized during the de-risk spike: if integrating it is genuinely small, ship it in v1; if it adds material scope/testing, defer to v1.1.

### D15 — 60-second clip cap
Covers nearly all messages while bounding latency and cost. Enforced client- and server-side.

### D16 — Mic blocked in keyboard extension → record in the container app (Spike #1 finding, 2026-06-17)
**Confirmed:** iOS does **not** allow microphone recording inside a keyboard extension, even with Full Access enabled and mic permission granted. `AVAudioRecorder.record()` returns false; the OS log states the extension "doesn't have entitlements to record audio." This is a platform-wide limitation — Gboard/SwiftKey/WeChat all hit it.

**What still works (proven in Spike #1):** KeyboardKit free core renders our custom keyboard view, inserts text via the proxy, and the flick-down digit gesture works. The backend `/transcribe` (Groq Whisper) is live.

**Decision:** Voice recording moves to the **container app** (apps can use the mic). Flow:
1. Keyboard mic button → `extensionContext.open("farsivoicekeyboard://dictate")` opens our app.
2. App records + POSTs to the Worker + gets text.
3. Result returns to the keyboard via the **system pasteboard** (works on the free account, no App Group) — or an **App Group** later (cleaner; may need the paid Apple Developer account).
4. On returning to the host app, the keyboard inserts the result.

UX = a brief bounce to our app per dictation (same as other iOS voice keyboards). First we prove the transcription pipeline directly in the container app, then build the bounce/return. (Also: Android keyboards CAN record mic directly — this limitation is iOS-only, noted for the future Android build.)
