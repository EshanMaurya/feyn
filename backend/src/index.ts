import Anthropic from "@anthropic-ai/sdk";
import { TutorRequestSchema, tutorReply } from "./tutor";

export interface Env {
  ANTHROPIC_API_KEY: string;
  TUTOR_MODEL: string;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

export async function handle(request: Request, client: Anthropic, model: string): Promise<Response> {
  const url = new URL(request.url);
  if (request.method === "GET" && url.pathname === "/health") return json({ ok: true });
  if (request.method !== "POST" || url.pathname !== "/v1/tutor") return json({ error: "not found" }, 404);

  const parsed = TutorRequestSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return json({ error: "invalid request", issues: parsed.error.issues }, 400);

  try {
    return json(await tutorReply(client, model, parsed.data));
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) return json({ error: "rate limited" }, 429);
    if (error instanceof Anthropic.APIError) return json({ error: "model error" }, 502);
    return json({ error: "tutor failed" }, 500);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // TODO: authenticate the app (e.g. App Attest) before going public.
    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
    return handle(request, client, env.TUTOR_MODEL);
  },
} satisfies ExportedHandler<Env>;
