import { mkdir } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { openclawAgentIdFor, workspacePathFor } from "../slug.js";
import type { StepContext, StepResult } from "./types.js";

const expandHome = (value: string): string => {
  if (value === "~") {
    return os.homedir();
  }
  if (value.startsWith("~/")) {
    return path.join(os.homedir(), value.slice(2));
  }
  return value;
};

export async function step3CreateWorkspace(ctx: StepContext): Promise<StepResult> {
  const workspaceSlug = ctx.state.workspaceSlug as string | undefined;
  if (!workspaceSlug) {
    return {
      ok: false,
      errorCode: "WORKSPACE_SLUG_MISSING",
      errorMessage: "workspace slug missing from state"
    };
  }

  const openclawAgentId = openclawAgentIdFor(workspaceSlug, ctx.input.agentName);
  const workspacePath = ctx.input.workspacePath ?? workspacePathFor(openclawAgentId);
  const resolvedWorkspacePath = expandHome(workspacePath);

  await mkdir(resolvedWorkspacePath, { recursive: true });

  return {
    ok: true,
    data: {
      openclawAgentId,
      workspacePath: resolvedWorkspacePath
    }
  };
}
