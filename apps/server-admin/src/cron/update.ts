import type { Elysia } from "elysia";
import { cron } from "@elysiajs/cron";
import { configManager } from "../lib/redis";
import { updateManager } from "../lib/update-manager";
import { getRuntimeCapabilities } from "../lib/runtime-profile";

export const registerUpdateCron = (app: Elysia) => {
  const capabilities = getRuntimeCapabilities();
  if (!capabilities.self_update_available) {
    return app;
  }

  const pattern = process.env.UPDATE_CRON || "0 */2 * * *";
  const lockTtlSeconds = 600;

  app.use(
    cron({
      name: "ota-update-check",
      pattern,
      async run() {
        try {
          const acquired = await configManager.setLockIfNotExists("ota-update-check", lockTtlSeconds);
          if (!acquired) {
            return;
          }
          await updateManager.checkNow("cron");
        } catch (error) {
          console.error("[update][cron] error:", error);
        }
      },
    })
  );

  return app;
};
