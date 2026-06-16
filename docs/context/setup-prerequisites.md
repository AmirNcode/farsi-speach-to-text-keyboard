# Setup & Prerequisites

Written for a **non-technical owner**. Each step says what to do and why.

## What the owner needs
| Item | Needed for | Status | Cost |
|---|---|---|---|
| **Mac** | Building iOS | ✅ have | — |
| **Xcode** | Building iOS (install from the Mac App Store) | to install | free |
| **iPhone** | Real mic/keyboard testing | have | — |
| **Cloudflare account** | Deploy the Worker backend | to set up | free |
| **Groq account + API key** | Whisper transcription | to set up | free dev tier |
| **Apple Developer Program** | Putting the app on **other people's** phones (TestFlight/App Store) | ⛔ not yet | $99/yr |

> **About the Apple Developer account:** You can build and test on **your own** iPhone without it (Xcode signs with your free Apple ID; apps last ~7 days then need a re-build). To install on **friends'/family's** phones, you need the **$99/yr** program (for TestFlight or the App Store). Get it when you're ready to share.

## Backend setup (one-time, do once)
1. Create a **Cloudflare** account (free).
2. Create a **Groq** account, generate an **API key**.
3. Install Wrangler: `npm i -g wrangler` (or use `npx wrangler`).
4. In `/backend`: `wrangler login`.
5. Set secrets:
   - `wrangler secret put GROQ_API_KEY` (paste the Groq key)
   - `wrangler secret put APP_TOKEN` (any long random string; also goes in the app build)
6. Deploy: `wrangler deploy`. Note the Worker URL — the app points at it.

## iOS setup (one-time)
1. Install **Xcode** from the Mac App Store.
2. Open `/ios` in Xcode.
3. Sign in with your Apple ID (Xcode → Settings → Accounts) — gives a free signing identity.
4. Set the Worker URL + `APP_TOKEN` in the app config.
5. Build & run on your iPhone (plugged in).
6. On the iPhone: **Settings → General → Keyboard → Keyboards → Add New Keyboard** → pick this keyboard.
7. Tap the keyboard → **Allow Full Access** (required for mic + network).

## Enabling the keyboard (every test device)
- Settings → General → Keyboard → Keyboards → **Add New Keyboard** → select it.
- Tap it again → **Allow Full Access = ON**.
- In any text field, tap the 🌐 globe to switch to it.

## Sharing with friends/family (later)
- Requires the **Apple Developer Program ($99/yr)**.
- Easiest path: **TestFlight** (invite by email, up to 10,000 testers, no public App Store listing needed).

## What the AI assistant cannot do from its environment
- Run Xcode, build/sign iOS apps, drive a real iPhone, or grant Full Access.
- Those steps are the owner's, on the Mac/iPhone — the assistant writes the code + exact instructions and the owner runs them.
