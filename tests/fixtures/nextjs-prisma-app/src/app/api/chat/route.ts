import { generateText } from "ai";
import { openai } from "@ai-sdk/openai";

export async function POST(request: Request) {
  const { prompt } = await request.json();
  const result = await generateText({ model: openai("gpt-4"), prompt });
  return Response.json({ text: result.text });
}
