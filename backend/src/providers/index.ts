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
