export async function POST(request: Request) {
  const data = await request.formData();
  const file = data.get("file") as File;
  const body = new FormData();
  body.append("file", file);
  return Response.json({ uploaded: true });
}
