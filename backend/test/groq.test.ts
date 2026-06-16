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
