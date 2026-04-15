import { copyFile, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import JSON5 from "json5";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const FOREMAN_INLINE_KEYS = ["env", "models", "plugins", "agents"] as const;

type JsonObject = Record<string, unknown>;

const isRecord = (value: unknown): value is JsonObject => {
  return typeof value === "object" && value !== null && !Array.isArray(value);
};

const parseConfig = (raw: string): JsonObject => {
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!isRecord(parsed)) {
      throw new Error("config root must be an object");
    }
    return parsed;
  } catch {
    const parsed = JSON5.parse(raw) as unknown;
    if (!isRecord(parsed)) {
      throw new Error("config root must be an object");
    }
    return parsed;
  }
};

const mergeRecords = (existing: unknown, incoming: unknown): unknown => {
  if (!isRecord(existing) || !isRecord(incoming)) {
    return incoming;
  }
  const output: JsonObject = { ...existing };
  for (const [key, value] of Object.entries(incoming)) {
    output[key] = mergeRecords(output[key], value);
  }
  return output;
};

const readConfigOrEmpty = async (configPath: string): Promise<JsonObject> => {
  try {
    const raw = await readFile(configPath, "utf8");
    return parseConfig(raw);
  } catch {
    return {};
  }
};

const verifyRootIsClean = async (rootPath: string, expectedInclude: string): Promise<void> => {
  const repairedRoot = parseConfig(await readFile(rootPath, "utf8"));
  if (repairedRoot.$include !== expectedInclude) {
    throw new Error(`expected $include=${expectedInclude}, got ${String(repairedRoot.$include ?? "")}`);
  }
  const stillInlined = FOREMAN_INLINE_KEYS.filter((key) => key in repairedRoot);
  if (stillInlined.length > 0) {
    throw new Error(`root config still has inlined keys: ${stillInlined.join(", ")}`);
  }
};

export async function runOpenClawAbsorptionRepairJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "openclaw_config_absorption_repair" });
  const rootPath = deps.env.OPENCLAW_CONFIG_PATH;
  const includePath = deps.env.OPENCLAW_INCLUDE_PATH;
  const expectedIncludeDirective = `./${path.basename(includePath)}`;

  const rootConfigRaw = await readFile(rootPath, "utf8");
  const rootConfig = parseConfig(rootConfigRaw);
  const inlinedKeys = FOREMAN_INLINE_KEYS.filter((key) => key in rootConfig);
  const includePresent = typeof rootConfig.$include === "string";

  if (includePresent && inlinedKeys.length === 0) {
    logger.info("config clean");
    return {
      jobName: "openclaw_config_absorption_repair",
      status: "noop",
      message: "config clean",
      details: { include: String(rootConfig.$include) }
    };
  }

  const includeConfig = await readConfigOrEmpty(includePath);
  const movedKeys: string[] = [];
  for (const key of inlinedKeys) {
    includeConfig[key] = mergeRecords(includeConfig[key], rootConfig[key]);
    delete rootConfig[key];
    movedKeys.push(key);
  }
  rootConfig.$include = expectedIncludeDirective;

  const backupSuffix = new Date().toISOString().replace(/[:.]/g, "-");
  const rootBackupPath = `${rootPath}.bak-${backupSuffix}`;
  const includeBackupPath = `${includePath}.bak-${backupSuffix}`;

  let includeExisted = false;
  let includeWritten = false;
  try {
    await copyFile(rootPath, rootBackupPath);
    try {
      await copyFile(includePath, includeBackupPath);
      includeExisted = true;
    } catch {
      includeExisted = false;
    }

    await mkdir(path.dirname(includePath), { recursive: true });
    await writeFile(includePath, `${JSON.stringify(includeConfig, null, 2)}\n`, "utf8");
    includeWritten = true;
    await writeFile(rootPath, `${JSON.stringify(rootConfig, null, 2)}\n`, "utf8");

    try {
      await deps.clients.openclaw.reloadSecrets();
    } catch (error) {
      logger.warn({ err: error }, "openclaw secrets reload failed; attempting gateway restart fallback");
      await deps.clients.openclaw.restartGateway();
    }
    await verifyRootIsClean(rootPath, expectedIncludeDirective);

    logger.info(
      { rootBackupPath, includeBackupPath: includeExisted ? includeBackupPath : null, movedKeys },
      "openclaw config absorption repair completed"
    );
    return {
      jobName: "openclaw_config_absorption_repair",
      status: "ok",
      message: "openclaw config repaired and secrets reloaded",
      details: {
        rootBackupPath,
        includeBackupPath: includeExisted ? includeBackupPath : null,
        includeDirective: expectedIncludeDirective,
        movedKeys
      }
    };
  } catch (error) {
    logger.error({ err: error }, "openclaw config absorption repair failed; restoring backups");
    await copyFile(rootBackupPath, rootPath);
    if (includeExisted) {
      await copyFile(includeBackupPath, includePath);
    } else if (includeWritten) {
      await rm(includePath, { force: true });
    }
    throw error;
  }
}
