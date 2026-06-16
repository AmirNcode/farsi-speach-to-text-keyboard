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
