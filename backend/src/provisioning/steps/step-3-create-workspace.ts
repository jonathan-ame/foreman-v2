import { copyFileSync, existsSync, readdirSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { CEO_ROLES } from "../model-tiers.js";
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

const resolveTemplateDir = (workspaceTemplate: string): string => {
  const direct = path.resolve(process.cwd(), workspaceTemplate);
  if (existsSync(direct)) {
    return direct;
  }
  const parent = path.resolve(process.cwd(), "..", workspaceTemplate);
  return parent;
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
  const roleSpecificTemplate = `config/${ctx.input.role.replace(/_/g, "-")}-workspace`;
  const workspaceTemplate = CEO_ROLES.has(ctx.input.role)
    ? "config/ceo-workspace"
    : existsSync(resolveTemplateDir(roleSpecificTemplate))
      ? roleSpecificTemplate
      : "config/worker-workspace";
  const templateDir = resolveTemplateDir(workspaceTemplate);
  const filesToCopy = CEO_ROLES.has(ctx.input.role)
    ? ["SOUL.md", "HEARTBEAT.md", "AGENTS.md", "USER.md", "IDENTITY.md"]
    : readdirSync(templateDir).filter((file) => file.endsWith(".md"));

  for (const file of filesToCopy) {
    const src = path.resolve(templateDir, file);
    const dest = path.resolve(resolvedWorkspacePath, file);
    if (existsSync(src)) {
      copyFileSync(src, dest);
    }
  }

  return {
    ok: true,
    data: {
      openclawAgentId,
      workspacePath: resolvedWorkspacePath
    }
  };
}

export async function rollbackStep3CreateWorkspace(ctx: StepContext): Promise<void> {
  const workspacePath = ctx.state.workspacePath as string | undefined;
  ctx.logger.info(
    { workspacePath: workspacePath ?? null },
    "rolling back step_3_create_workspace: cleanup deferred to maintenance task"
  );
}
