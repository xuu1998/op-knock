import { describe, test } from "node:test";
import assert from "node:assert/strict";
import { isHmacRequiredForPath } from "./hmac.ts";

describe("isHmacRequiredForPath", () => {
  test("does not require hmac for browser auth api routes", () => {
    assert.equal(isHmacRequiredForPath("/api/auth/bootstrap"), false);
    assert.equal(isHmacRequiredForPath("/api/auth/session"), false);
    assert.equal(isHmacRequiredForPath("/auth/api/auth/bootstrap"), false);
    assert.equal(isHmacRequiredForPath("/__auth__/api/auth/session"), false);
  });

  test("still requires hmac for protected admin api routes", () => {
    assert.equal(isHmacRequiredForPath("/api/admin/users"), true);
    assert.equal(isHmacRequiredForPath("/api/waf/rules"), true);
  });
});
