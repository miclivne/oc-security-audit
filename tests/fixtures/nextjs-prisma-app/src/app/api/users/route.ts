import { getSession } from "@/lib/auth";

export async function GET() {
  const session = await getSession();
  return Response.json({ user: session.user });
}

export async function POST() {
  const session = await getSession();
  return Response.json({ created: true });
}
