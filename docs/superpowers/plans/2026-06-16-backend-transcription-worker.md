# Backend Transcription Worker — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Cloudflare Worker that the keyboard calls to turn recorded audio into text — a thin, tested proxy that keeps the provider key off the device and forwards audio to Groq's Whisper large-v3.

**Architecture:** A single `POST /transcribe` endpoint. The handler validates a shared app token, parses the uploaded audio, enforces a size cap, and delegates to a `TranscriptionProvider`. Groq is the only provider today, selected by a factory so others (Cloudflare Workers AI, self-hosted) drop in later without touching callers. Pure logic (handler, provider, helpers) is unit-tested with mocked `fetch`; a real Groq call is an opt-in integration test.

**Tech Stack:** TypeScript · Cloudflare Workers (Wrangler) · Vitest · Groq OpenAI-compatible `/audio/transcriptions` (`whisper-large-v3`).

**Working directory for all tasks:** `/Users/amir/Workspace/FarsiVoiceKeyboard/backend`

---

## File structure (locked before tasks)

```
backend/
  package.json            # scripts + dev deps
  tsconfig.json           # TS config
  wrangler.toml           # Worker config (name, entry, compat date)
  vitest.config.ts        # test runner config
  .dev.vars.example       # documents required local secrets (no real values)
  src/
    env.ts                # Env type (APP_TOKEN, GROQ_API_KEY, PROVIDER?)
    http.ts               # json() response helper
    handler.ts            # handleTranscribe(request, env, provider): validation + delegation
    providers/
      types.ts            # TranscriptionResult + TranscriptionProvider interface
      groq.ts             # GroqProvider (calls Groq, parses response)
      index.ts            # createProvider(env) factory
    index.ts              # Worker entry: routes /transcribe, /health, 404
  test/
    http.test.ts
    groq.test.ts
    providers.test.ts
    handler.test.ts
    index.test.ts
    integration.test.ts   # opt-in real Groq call (skipped without key+fixtures)
    fixtures/             # (optional) real audio clips for integration test
```

Responsibilities, one per file: `http.ts` builds responses; `handler.ts` owns request validation + flow; `providers/*` owns talking to transcription services; `index.ts` only routes. Files that change together (each provider) live together under `providers/`.

---

### Task 1: Scaffold project + `json()` response helper

**Files:**
- Create: `backend/package.json`
- Create: `backend/tsconfig.json`
- Create: `backend/wrangler.toml`
- Create: `backend/vitest.config.ts`
- Create: `backend/.dev.vars.example`
- Create: `backend/src/http.ts`
- Test: `backend/test/http.test.ts`

- [ ] **Step 1: Create `backend/package.json`**

```json
{
  "name": "farsi-voice-keyboard-backend",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20240909.0",
    "typescript": "^5.6.0",
    "vitest": "^2.1.0",
    "wrangler": "^3.80.0"
  }
}
```

- [ ] **Step 2: Create `backend/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true,
    "esModuleInterop": true,
    "verbatimModuleSyntax": false
  },
  "include": ["src", "test"]
}
```

- [ ] **Step 3: Create `backend/wrangler.toml`**

```toml
name = "farsi-voice-keyboard"
main = "src/index.ts"
compatibility_date = "2024-09-23"

# Secrets (set with `wrangler secret put`): GROQ_API_KEY, APP_TOKEN
[vars]
PROVIDER = "groq"
```

- [ ] **Step 4: Create `backend/vitest.config.ts`**

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: { environment: "node", include: ["test/**/*.test.ts"] },
});
```

- [ ] **Step 5: Create `backend/.dev.vars.example`**

```
# Copy to .dev.vars and fill in for `wrangler dev`. .dev.vars is gitignored.
APP_TOKEN=replace-with-a-long-random-string
GROQ_API_KEY=replace-with-your-groq-key
PROVIDER=groq
```

- [ ] **Step 6: Write the failing test** — `backend/test/http.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { json } from "../src/http";

describe("json", () => {
  it("sets status, content-type, and JSON body", async () => {
    const res = json(200, { text: "hi", language: "en" });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/json");
    expect(await res.json()).toEqual({ text: "hi", language: "en" });
  });

  it("carries through error status codes", () => {
    expect(json(401, { error: "unauthorized" }).status).toBe(401);
  });
});
```

- [ ] **Step 7: Install deps and run the test to verify it fails**

Run: `cd backend && npm install && npm test`
Expected: FAIL — cannot resolve `../src/http` (module not found).

- [ ] **Step 8: Implement `backend/src/http.ts`**

```ts
export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
```

- [ ] **Step 9: Run the test to verify it passes**

Run: `cd backend && npm test`
Expected: PASS (2 passing).

- [ ] **Step 10: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/package.json backend/package-lock.json backend/tsconfig.json backend/wrangler.toml backend/vitest.config.ts backend/.dev.vars.example backend/src/http.ts backend/test/http.test.ts
git commit -m "feat(backend): scaffold worker project + json helper"
```

---

### Task 2: `GroqProvider` (talks to Groq, parses response)

**Files:**
- Create: `backend/src/providers/types.ts`
- Create: `backend/src/providers/groq.ts`
- Test: `backend/test/groq.test.ts`

- [ ] **Step 1: Create the interface** — `backend/src/providers/types.ts`

```ts
export interface TranscriptionResult {
  text: string;
  language: string;
}

export interface TranscriptionProvider {
  transcribe(audio: Blob, languageHint?: string): Promise<TranscriptionResult>;
}

export class ProviderError extends Error {}
```

- [ ] **Step 2: Write the failing test** — `backend/test/groq.test.ts`

```ts
import { describe, it, expect, vi, afterEach } from "vitest";
import { GroqProvider } from "../src/providers/groq";

afterEach(() => vi.restoreAllMocks());

function mockFetchOnce(status: number, body: unknown) {
  return vi.spyOn(globalThis, "fetch").mockResolvedValue(
    new Response(JSON.stringify(body), { status })
  );
}

describe("GroqProvider", () => {
  it("posts audio to Groq with model + language hint and parses text/language", async () => {
    const spy = mockFetchOnce(200, { text: "سلام", language: "fa" });
    const provider = new GroqProvider("test-key");

    const result = await provider.transcribe(new Blob(["x"]), "fa");

    expect(result).toEqual({ text: "سلام", language: "fa" });
    const [url, init] = spy.mock.calls[0];
    expect(url).toBe("https://api.groq.com/openai/v1/audio/transcriptions");
    expect((init as RequestInit).method).toBe("POST");
    expect((init as any).headers.Authorization).toBe("Bearer test-key");
    const form = (init as RequestInit).body as FormData;
    expect(form.get("model")).toBe("whisper-large-v3");
    expect(form.get("language")).toBe("fa");
    expect(form.get("response_format")).toBe("verbose_json");
  });

  it("omits language when no hint is given", async () => {
    const spy = mockFetchOnce(200, { text: "hello", language: "en" });
    await new GroqProvider("k").transcribe(new Blob(["x"]));
    const form = (spy.mock.calls[0][1] as RequestInit).body as FormData;
    expect(form.get("language")).toBeNull();
  });

  it("throws ProviderError on non-2xx from Groq", async () => {
    mockFetchOnce(500, { error: "boom" });
    await expect(new GroqProvider("k").transcribe(new Blob(["x"]))).rejects.toThrow();
  });
});
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd backend && npx vitest run groq`
Expected: FAIL — cannot resolve `../src/providers/groq`.

- [ ] **Step 4: Implement `backend/src/providers/groq.ts`**

```ts
import { ProviderError, type TranscriptionProvider, type TranscriptionResult } from "./types";

const GROQ_URL = "https://api.groq.com/openai/v1/audio/transcriptions";

export class GroqProvider implements TranscriptionProvider {
  constructor(
    private readonly apiKey: string,
    private readonly model = "whisper-large-v3",
  ) {}

  async transcribe(audio: Blob, languageHint?: string): Promise<TranscriptionResult> {
    const form = new FormData();
    form.append("file", audio, "audio.m4a");
    form.append("model", this.model);
    form.append("response_format", "verbose_json");
    if (languageHint) form.append("language", languageHint);

    const res = await fetch(GROQ_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${this.apiKey}` },
      body: form,
    });

    if (!res.ok) {
      throw new ProviderError(`groq request failed: ${res.status}`);
    }

    const data = (await res.json()) as { text?: string; language?: string };
    return {
      text: data.text ?? "",
      language: data.language ?? languageHint ?? "unknown",
    };
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd backend && npx vitest run groq`
Expected: PASS (3 passing).

- [ ] **Step 6: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/src/providers/types.ts backend/src/providers/groq.ts backend/test/groq.test.ts
git commit -m "feat(backend): GroqProvider with Whisper large-v3 transcription"
```

---

### Task 3: Provider factory + `Env` type

**Files:**
- Create: `backend/src/env.ts`
- Create: `backend/src/providers/index.ts`
- Test: `backend/test/providers.test.ts`

- [ ] **Step 1: Create `backend/src/env.ts`**

```ts
export interface Env {
  APP_TOKEN: string;
  GROQ_API_KEY: string;
  PROVIDER?: string;
}
```

- [ ] **Step 2: Write the failing test** — `backend/test/providers.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { createProvider } from "../src/providers";
import { GroqProvider } from "../src/providers/groq";
import type { Env } from "../src/env";

const baseEnv: Env = { APP_TOKEN: "t", GROQ_API_KEY: "k" };

describe("createProvider", () => {
  it("returns a GroqProvider by default", () => {
    expect(createProvider(baseEnv)).toBeInstanceOf(GroqProvider);
  });

  it("returns a GroqProvider when PROVIDER=groq", () => {
    expect(createProvider({ ...baseEnv, PROVIDER: "groq" })).toBeInstanceOf(GroqProvider);
  });

  it("throws on an unknown provider", () => {
    expect(() => createProvider({ ...baseEnv, PROVIDER: "nope" })).toThrow(/unknown provider/);
  });
});
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd backend && npx vitest run providers`
Expected: FAIL — cannot resolve `../src/providers`.

- [ ] **Step 4: Implement `backend/src/providers/index.ts`**

```ts
import type { Env } from "../env";
import { GroqProvider } from "./groq";
import type { TranscriptionProvider } from "./types";

export function createProvider(env: Env): TranscriptionProvider {
  const which = env.PROVIDER ?? "groq";
  switch (which) {
    case "groq":
      return new GroqProvider(env.GROQ_API_KEY);
    default:
      throw new Error(`unknown provider: ${which}`);
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd backend && npx vitest run providers`
Expected: PASS (3 passing).

- [ ] **Step 6: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/src/env.ts backend/src/providers/index.ts backend/test/providers.test.ts
git commit -m "feat(backend): provider factory + Env type"
```

---

### Task 4: `handleTranscribe` — validation + delegation

**Files:**
- Create: `backend/src/handler.ts`
- Test: `backend/test/handler.test.ts`

- [ ] **Step 1: Write the failing test** — `backend/test/handler.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { handleTranscribe, MAX_AUDIO_BYTES } from "../src/handler";
import type { Env } from "../src/env";
import type { TranscriptionProvider, TranscriptionResult } from "../src/providers/types";

const env: Env = { APP_TOKEN: "secret", GROQ_API_KEY: "k" };

const okProvider: TranscriptionProvider = {
  async transcribe(_audio, hint): Promise<TranscriptionResult> {
    return { text: "result", language: hint ?? "en" };
  },
};

function req(opts: { token?: string; audio?: Blob; language?: string } = {}): Request {
  const form = new FormData();
  if (opts.audio) form.append("audio", opts.audio, "audio.m4a");
  if (opts.language) form.append("language", opts.language);
  const headers: Record<string, string> = {};
  if (opts.token !== undefined) headers["X-App-Token"] = opts.token;
  return new Request("https://w/transcribe", { method: "POST", headers, body: form });
}

describe("handleTranscribe", () => {
  it("401 when token missing", async () => {
    const res = await handleTranscribe(req({ audio: new Blob(["x"]) }), env, okProvider);
    expect(res.status).toBe(401);
  });

  it("401 when token wrong", async () => {
    const res = await handleTranscribe(req({ token: "bad", audio: new Blob(["x"]) }), env, okProvider);
    expect(res.status).toBe(401);
  });

  it("400 when audio missing", async () => {
    const res = await handleTranscribe(req({ token: "secret" }), env, okProvider);
    expect(res.status).toBe(400);
  });

  it("413 when audio too large", async () => {
    const big = new Blob([new Uint8Array(MAX_AUDIO_BYTES + 1)]);
    const res = await handleTranscribe(req({ token: "secret", audio: big }), env, okProvider);
    expect(res.status).toBe(413);
  });

  it("200 with text + language, passing the language hint to the provider", async () => {
    const res = await handleTranscribe(
      req({ token: "secret", audio: new Blob(["x"]), language: "fa" }),
      env,
      okProvider,
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ text: "result", language: "fa" });
  });

  it("502 when the provider throws", async () => {
    const bad: TranscriptionProvider = {
      async transcribe() { throw new Error("upstream down"); },
    };
    const res = await handleTranscribe(req({ token: "secret", audio: new Blob(["x"]) }), env, bad);
    expect(res.status).toBe(502);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run handler`
Expected: FAIL — cannot resolve `../src/handler`.

- [ ] **Step 3: Implement `backend/src/handler.ts`**

```ts
import type { Env } from "./env";
import { json } from "./http";
import type { TranscriptionProvider } from "./providers/types";

// ~5 MB: comfortably covers 60s of 16kHz mono m4a while bounding abuse.
export const MAX_AUDIO_BYTES = 5 * 1024 * 1024;

export async function handleTranscribe(
  request: Request,
  env: Env,
  provider: TranscriptionProvider,
): Promise<Response> {
  if (request.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }

  const token = request.headers.get("X-App-Token");
  if (!token || token !== env.APP_TOKEN) {
    return json(401, { error: "unauthorized" });
  }

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return json(400, { error: "bad_request" });
  }

  const audio = form.get("audio");
  if (!(audio instanceof Blob)) {
    return json(400, { error: "missing_audio" });
  }
  if (audio.size > MAX_AUDIO_BYTES) {
    return json(413, { error: "audio_too_large" });
  }

  const languageRaw = form.get("language");
  const language = typeof languageRaw === "string" && languageRaw ? languageRaw : undefined;

  try {
    const result = await provider.transcribe(audio, language);
    return json(200, result);
  } catch {
    return json(502, { error: "provider_failed" });
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run handler`
Expected: PASS (6 passing).

- [ ] **Step 5: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/src/handler.ts backend/test/handler.test.ts
git commit -m "feat(backend): /transcribe handler with token/size validation"
```

---

### Task 5: Worker entry + routing

**Files:**
- Create: `backend/src/index.ts`
- Test: `backend/test/index.test.ts`

- [ ] **Step 1: Write the failing test** — `backend/test/index.test.ts`

```ts
import { describe, it, expect } from "vitest";
import worker from "../src/index";
import type { Env } from "../src/env";

const env: Env = { APP_TOKEN: "secret", GROQ_API_KEY: "k" };

describe("worker.fetch routing", () => {
  it("GET /health returns ok", async () => {
    const res = await worker.fetch(new Request("https://w/health"), env);
    expect(res.status).toBe(200);
    expect(await res.text()).toBe("ok");
  });

  it("unknown path returns 404", async () => {
    const res = await worker.fetch(new Request("https://w/nope"), env);
    expect(res.status).toBe(404);
  });

  it("routes /transcribe through the handler (401 without token)", async () => {
    const res = await worker.fetch(
      new Request("https://w/transcribe", { method: "POST", body: new FormData() }),
      env,
    );
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run index`
Expected: FAIL — cannot resolve `../src/index`.

- [ ] **Step 3: Implement `backend/src/index.ts`**

```ts
import type { Env } from "./env";
import { handleTranscribe } from "./handler";
import { createProvider } from "./providers";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { pathname } = new URL(request.url);

    if (pathname === "/health") {
      return new Response("ok");
    }
    if (pathname === "/transcribe") {
      return handleTranscribe(request, env, createProvider(env));
    }
    return new Response("not found", { status: 404 });
  },
};
```

- [ ] **Step 4: Run the full suite to verify everything passes**

Run: `cd backend && npm test`
Expected: PASS (all suites, ~17 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/src/index.ts backend/test/index.test.ts
git commit -m "feat(backend): worker entry with /health, /transcribe routing"
```

---

### Task 6: Opt-in real-Groq integration test + backend README

**Files:**
- Create: `backend/test/integration.test.ts`
- Create: `backend/README.md`

- [ ] **Step 1: Create the opt-in integration test** — `backend/test/integration.test.ts`

This test only runs when `GROQ_API_KEY` is set in the environment **and** a fixture clip exists; otherwise it is skipped, so CI/local runs stay green without secrets.

```ts
import { describe, it, expect } from "vitest";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { GroqProvider } from "../src/providers/groq";

const key = process.env.GROQ_API_KEY;
const fixture = new URL("./fixtures/sample-fa.m4a", import.meta.url);
const hasFixture = existsSync(fixture);
const run = key && hasFixture ? describe : describe.skip;

run("GroqProvider (real Groq call)", () => {
  it("transcribes a Farsi clip to non-empty text", async () => {
    const bytes = await readFile(fixture);
    const provider = new GroqProvider(key!);
    const result = await provider.transcribe(new Blob([bytes]), "fa");
    expect(result.text.trim().length).toBeGreaterThan(0);
    expect(result.language).toBe("fa");
  }, 30_000);
});
```

- [ ] **Step 2: Verify it is skipped (no key/fixture) and the suite stays green**

Run: `cd backend && npm test`
Expected: PASS, with the integration suite reported as **skipped**.

- [ ] **Step 3: Create `backend/README.md`**

````markdown
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
````

- [ ] **Step 4: Commit**

```bash
cd /Users/amir/Workspace/FarsiVoiceKeyboard
git add backend/test/integration.test.ts backend/README.md
git commit -m "test(backend): opt-in Groq integration test + README"
```

---

### Task 7: Deploy & smoke-test (owner-run; needs Cloudflare + Groq accounts)

> This task runs on a machine with the Cloudflare/Groq accounts set up (see `docs/context/setup-prerequisites.md`). It is not unit-testable; it verifies the live endpoint.

- [ ] **Step 1: Authenticate Wrangler**

Run: `cd backend && npx wrangler login`
Expected: browser opens; CLI reports logged in.

- [ ] **Step 2: Set secrets**

```bash
cd backend
npx wrangler secret put GROQ_API_KEY   # paste Groq key
npx wrangler secret put APP_TOKEN      # paste a long random string; SAVE this value for the app
```

- [ ] **Step 3: Deploy**

Run: `cd backend && npm run deploy`
Expected: prints a Worker URL like `https://farsi-voice-keyboard.<subdomain>.workers.dev`. Record it for the iOS app.

- [ ] **Step 4: Smoke-test health**

Run: `curl https://farsi-voice-keyboard.<subdomain>.workers.dev/health`
Expected: `ok`

- [ ] **Step 5: Smoke-test transcription with a real clip**

```bash
curl -X POST https://farsi-voice-keyboard.<subdomain>.workers.dev/transcribe \
  -H "X-App-Token: <APP_TOKEN>" \
  -F "audio=@/path/to/a/short.m4a" \
  -F "language=fa"
```
Expected: JSON `{ "text": "...", "language": "fa" }` with sensible Farsi text.

- [ ] **Step 6: Record the live values**

Note the **Worker URL** and **APP_TOKEN** — the iOS plan needs both. Do not commit them.

---

## Notes for the executor
- Add a `backend/.gitignore` line set in Task 1's commit if not already covered by the repo root `.gitignore` (it covers `node_modules/`, `.dev.vars`, `.wrangler/`). No separate backend gitignore is required.
- Node 20+ is required (global `fetch`, `FormData`, `Blob`, `File`).
- If `wrangler.toml` ever needs Node built-ins, add `compatibility_flags = ["nodejs_compat"]`; the current code uses only Web-standard APIs, so it does not.
