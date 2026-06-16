# Backend — Transcription Worker

Cloudflare Worker that turns recorded audio into text via Groq's Whisper large-v3.
See `../docs/context/backend.md` for the full design.

## Develop
```bash
npm install
npm test            # unit tests (no secrets needed)
cp .dev.vars.example .dev.vars   # then fill in APP_TOKEN + GROQ_API_KEY
npm run dev         # local server at http://localhost:8787
```

## Deploy
```bash
wrangler login
wrangler secret put GROQ_API_KEY   # paste your Groq key
wrangler secret put APP_TOKEN      # any long random string (also goes in the app)
npm run deploy                     # prints your Worker URL
```

## API
`POST /transcribe`
- Header: `X-App-Token: <APP_TOKEN>`
- Body (multipart/form-data): `audio` (m4a, ≤5MB), `language` (optional `fa`/`en`)
- 200: `{ "text": "...", "language": "fa" }`
- Errors: 400 / 401 / 413 / 502

`GET /health` → `ok`

## Real transcription test (optional)
Put a short Farsi clip at `test/fixtures/sample-fa.m4a`, then:
```bash
GROQ_API_KEY=your-key npm test
```
