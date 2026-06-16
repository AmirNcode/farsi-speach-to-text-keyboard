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
