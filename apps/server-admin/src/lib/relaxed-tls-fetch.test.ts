import { describe, test } from "node:test";
import assert from "node:assert/strict";
import { getRequestOptionsForFetchWithTls } from "./relaxed-tls-fetch.ts";

describe("getRequestOptionsForFetchWithTls", () => {
  test("keeps https certificate validation enabled by default", () => {
    const options = getRequestOptionsForFetchWithTls(new URL("https://example.com"));

    assert.equal(options.rejectUnauthorized, undefined);
  });

  test("does not add rejectUnauthorized for http requests", () => {
    const options = getRequestOptionsForFetchWithTls(new URL("http://example.com"));

    assert.equal("rejectUnauthorized" in options, false);
  });
});
