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
