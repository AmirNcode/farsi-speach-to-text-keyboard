# Roadmap

## v1 (current spec) — iOS lean keyboard
- EN + FA layouts (FA = RTL), globe toggle.
- Flick-down numbers (digits match language).
- Voice-to-text: tap mic → speak → Stop → insert; Whisper large-v3 via Cloudflare Worker → Groq.
- Container app: onboarding (enable keyboard + Full Access) + settings (default language, digit style).
- Emoji **if cheap** (D14), else first item in v1.1.
- Free / near-zero cost; friends & family.

## v1.1 — fast follows
- Emoji keyboard (if deferred from v1).
- Recording polish (cancel, re-record), better error UX.
- Settings: haptics toggle, key-popup toggle.

## v2 — monetization + Android
- **Accounts + freemium/subscription** enforced in the Worker (free monthly minutes, paid unlimited).
- **Android keyboard** (InputMethodService; reuse layout definitions + same backend; Florisboard is a possible base).
- Provider/cost tuning (compare Groq vs Cloudflare vs self-host on accuracy & price).

## v3+ — quality & reach
- Autocorrect + word prediction for Farsi.
- Custom themes.
- Code-switching (mixed Farsi/English in one utterance).
- Streaming/live dictation.
- On-device English fallback for offline/fast cases.
- **Self-hosted private Whisper** provider for privacy-sensitive (e.g. Iran-based) users — backend-only swap thanks to the provider abstraction.

## Guiding principles
- YAGNI: don't build ahead of need.
- Keep the provider swappable and the Worker as the chokepoint, so cost/privacy/billing changes never require an app rewrite.
- Prove Farsi quality before charging.
