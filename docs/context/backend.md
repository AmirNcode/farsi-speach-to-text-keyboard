# Backend — Cloudflare Worker

A thin proxy between the keyboard and the Whisper provider. Keeps the provider key off the device, hints the language, and abstracts the provider.

## Stack
- **Cloudflare Workers** (TypeScript), managed with **Wrangler**.
- Free tier covers friends/family volume.
- Tests: **Vitest + Miniflare** (or `wrangler dev` for manual checks).

## API contract

### `POST /transcribe`
- **Headers**
  - `X-App-Token: <shared secret>` — v1 abuse deterrent (NOT real auth; replaced by accounts later).
- **Body** — `multipart/form-data`
  - `audio` — clip, m4a/16kHz mono, ≤60s
  - `language` — optional ISO-639-1 hint (`fa` | `en`)
- **200** — `{ "text": "string", "language": "fa" }`
- **Errors**
  - `400` malformed request / missing audio
  - `401` bad or missing `X-App-Token`
  - `413` clip exceeds size/duration cap
  - `502` upstream provider failure

## Provider abstraction
```ts
interface TranscriptionProvider {
  transcribe(audio: Blob, languageHint?: string): Promise<{ text: string; language: string }>;
}
```
- `GroqProvider` (default) → POST to Groq's OpenAI-compatible
  `https://api.groq.com/openai/v1/audio/transcriptions`, model `whisper-large-v3`,
  passing `language` when hinted, `response_format=json`.
- Future: `CloudflareAIProvider` (`@cf/openai/whisper-large-v3-turbo` via the `AI` binding),
  `SelfHostedProvider` (whisper.cpp endpoint). Select via `PROVIDER` env var.

## Config / secrets (Wrangler)
- `GROQ_API_KEY` — `wrangler secret put GROQ_API_KEY`
- `APP_TOKEN` — `wrangler secret put APP_TOKEN` (also embedded in the app build for v1)
- `PROVIDER` — var, defaults to `groq`

## Provider notes (verified 2026-06-16)
- **Groq:** `whisper-large-v3` (best multilingual accuracy, incl. Persian) and `whisper-large-v3-turbo`; OpenAI-compatible; free dev tier. `language` is an optional ISO-639-1 hint; auto-detected if omitted.
- **Cloudflare Workers AI:** `@cf/openai/whisper-large-v3-turbo`, 10,000 neurons/day free then ~$0.00051/audio-min. Good backup; callable via the Worker's `AI` binding (no separate key).

## Why a proxy (not direct calls)
- Keeps the provider key out of the app binary.
- Provider swap = backend-only change, no app release.
- It's the future home of accounts, free-minute limits, and subscription enforcement.

## Future
- Add auth (replace `APP_TOKEN`), per-user usage metering, and the subscription gate here.
- Optionally add a self-hosted private Whisper provider for privacy-sensitive users.
