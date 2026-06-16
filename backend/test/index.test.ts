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
