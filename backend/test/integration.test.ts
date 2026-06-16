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
