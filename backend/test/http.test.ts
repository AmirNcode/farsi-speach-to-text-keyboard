import { describe, it, expect } from "vitest";
import { json } from "../src/http";

describe("json", () => {
  it("sets status, content-type, and JSON body", async () => {
    const res = json(200, { text: "hi", language: "en" });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/json");
    expect(await res.json()).toEqual({ text: "hi", language: "en" });
  });

  it("carries through error status codes", () => {
    expect(json(401, { error: "unauthorized" }).status).toBe(401);
  });
});
