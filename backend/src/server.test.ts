import { app } from "./server.js";

describe("GET /health", () => {
  it("returns status ok", async () => {
    const response = await app.request("/health");
    expect(response.status).toBe(200);

    const body = (await response.json()) as { status: string };
    expect(body.status).toBe("ok");
  });
});
