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

  // At runtime a file field is a Blob/File; some @cloudflare/workers-types
  // versions under-type FormData.get, so we state the shape explicitly.
  const audio = form.get("audio") as Blob | string | null;
  if (audio === null || typeof audio === "string") {
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
