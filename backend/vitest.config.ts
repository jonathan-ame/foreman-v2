import { defineConfig } from "vitest/config";

const runE2E = process.env.FOREMAN_RUN_E2E === "1";
const runIntegration = process.env.FOREMAN_RUN_INTEGRATION === "1";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    exclude: [
      "node_modules/**",
      "dist/**",
      ...(runE2E ? [] : ["test/e2e/**"]),
      ...(runIntegration ? [] : ["test/rls-isolation.test.ts"])
    ],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"],
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.test.ts", "src/cli/**"]
    }
  }
});
