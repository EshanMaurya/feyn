import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { z } from "zod";

/** Mirrors FeynCore.TutorRequest (Swift encodes Data as base64). */
export const TutorRequestSchema = z.object({
  topic: z.string().min(1),
  mode: z.enum(["live", "onPause", "endOfExplanation"]),
  history: z
    .array(z.object({ role: z.enum(["learner", "tutor"]), text: z.string() }))
    .default([]),
  newSpeech: z.string(),
  canvasPNG: z.string().optional(),
});
export type TutorRequest = z.infer<typeof TutorRequestSchema>;

/** Mirrors FeynCore.TutorReply. */
export const TutorReplySchema = z.object({
  kind: z.enum(["question", "correction", "encouragement"]),
  text: z.string(),
});
export type TutorReply = z.infer<typeof TutorReplySchema>;

const MODE_GUIDANCE: Record<TutorRequest["mode"], string> = {
  live: "You are interjecting mid-explanation. Be very brief: one short sentence.",
  onPause: "The learner just paused. Respond in one or two short sentences.",
  endOfExplanation:
    "The learner has finished explaining. Point to the single most important gap or error, then ask one question.",
};

export function systemPrompt(mode: TutorRequest["mode"]): string {
  return [
    "You are Feyn, a Socratic tutor applying the Feynman technique.",
    "The learner is explaining a concept aloud while writing or drawing on a canvas.",
    "Your job is to find where their understanding is shaky and help them see it themselves:",
    "- Prefer a probing question over telling them the answer.",
    "- If something they said or wrote is factually wrong, correct it plainly and briefly (kind: correction).",
    "- If they skipped a step or used jargon without explaining it, ask them to explain it simply (kind: question).",
    "- Only use kind: encouragement when the explanation is genuinely clear and correct; still suggest what to explain next.",
    "Your reply is read aloud, so write natural spoken English: no lists, markdown, or symbols.",
    MODE_GUIDANCE[mode],
  ].join("\n");
}

export function buildUserContent(req: TutorRequest): Anthropic.ContentBlockParam[] {
  const content: Anthropic.ContentBlockParam[] = [];
  if (req.canvasPNG) {
    content.push({
      type: "image",
      source: { type: "base64", media_type: "image/png", data: req.canvasPNG },
    });
  }
  const transcript = req.history
    .map((t) => `${t.role === "learner" ? "Learner" : "Feyn"}: ${t.text}`)
    .join("\n");
  content.push({
    type: "text",
    text: [
      `Topic: ${req.topic}`,
      transcript ? `Conversation so far:\n${transcript}` : "",
      `Learner just said: ${req.newSpeech}`,
      req.canvasPNG ? "The image is the learner's current canvas." : "",
    ]
      .filter(Boolean)
      .join("\n\n"),
  });
  return content;
}

export async function tutorReply(
  client: Anthropic,
  model: string,
  req: TutorRequest,
): Promise<TutorReply> {
  const response = await client.messages.parse({
    model,
    max_tokens: 1024,
    system: systemPrompt(req.mode),
    messages: [{ role: "user", content: buildUserContent(req) }],
    output_config: { effort: "low", format: zodOutputFormat(TutorReplySchema) },
  });
  if (response.stop_reason === "refusal" || !response.parsed_output) {
    throw new Error(`No usable tutor reply (stop_reason: ${response.stop_reason})`);
  }
  return response.parsed_output;
}
