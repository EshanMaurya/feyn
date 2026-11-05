import Anthropic from "@anthropic-ai/sdk";
import { describe, expect, it, vi } from "vitest";
import { handle } from "../src/index";
import { buildUserContent, systemPrompt } from "../src/tutor";

function fakeClient(parse: (...args: unknown[]) => unknown) {
  return { messages: { parse: vi.fn(parse) } } as unknown as Anthropic;
}

const post = (body: unknown) =>
  new Request("https://feyn.test/v1/tutor", { method: "POST", body: JSON.stringify(body) });

describe("tutor prompt", () => {
  it("puts the canvas image before the text", () => {
    const content = buildUserContent({
      topic: "Entropy", mode: "onPause", history: [], newSpeech: "It is disorder", canvasPNG: "iVA=",
    });
    expect(content[0]).toMatchObject({ type: "image", source: { data: "iVA=" } });
    expect(content[1]).toMatchObject({ type: "text" });
  });

  it("adapts to the intervention mode", () => {
    expect(systemPrompt("live")).toContain("one short sentence");
    expect(systemPrompt("endOfExplanation")).toContain("finished explaining");
  });
});

describe("POST /v1/tutor", () => {
  it("returns the parsed tutor reply", async () => {
    const client = fakeClient(async () => ({
      stop_reason: "end_turn",
      parsed_output: { kind: "question", text: "Disorder of what, exactly?" },
    }));
    const res = await handle(post({ topic: "Entropy", mode: "live", newSpeech: "It is disorder" }), client, "claude-haiku-5-5");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ kind: "question", text: "Disorder of what, exactly?" });
    expect(client.messages.parse).toHaveBeenCalledWith(expect.objectContaining({ model: "claude-haiku-5-5" }));
  });

  it("rejects malformed requests without calling the model", async () => {
    const client = fakeClient(async () => ({}));
    const res = await handle(post({ mode: "sometimes" }), client, "m");
    expect(res.status).toBe(400);
    expect(client.messages.parse).not.toHaveBeenCalled();
  });

  it("maps a refusal to a 500", async () => {
    const client = fakeClient(async () => ({ stop_reason: "refusal", parsed_output: null }));
    const res = await handle(post({ topic: "x", mode: "onPause", newSpeech: "y" }), client, "m");
    expect(res.status).toBe(500);
  });
});
