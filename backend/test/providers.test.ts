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
