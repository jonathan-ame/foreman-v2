import { neon } from "@neondatabase/serverless";
import { readFileSync, readdirSync } from "node:fs";
import { resolve, basename } from "node:path";
import process from "node:process";

const DATABASE_URL = process.env.NEON_DATABASE_URL || process.env.DATABASE_URL;
if (!DATABASE_URL) {
  process.stderr.write("NEON_DATABASE_URL (or DATABASE_URL) is required — Neon connection string\n");
  process.exit(1);
}

const sql = neon(DATABASE_URL);

async function getAppliedMigrations(): Promise<Set<string>> {
  const rows = await sql`SELECT filename FROM _migrations ORDER BY applied_at`;
  return new Set(rows.map((r: { filename: string }) => r.filename));
}

async function recordMigration(filename: string): Promise<void> {
  await sql`INSERT INTO _migrations (filename) VALUES (${filename})`;
}

async function runMigrations(migrationsDir: string, options: { dryRun?: boolean; target?: string }): Promise<void> {
  const applied = await getAppliedMigrations();
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  const toApply = options.target
    ? files.filter((f) => f <= options.target!)
    : files;

  const pending = toApply.filter((f) => !applied.has(f));

  if (pending.length === 0) {
    process.stdout.write("No pending migrations.\n");
    return;
  }

  process.stdout.write(`Found ${pending.length} pending migration(s):\n`);
  for (const f of pending) {
    process.stdout.write(`  - ${f}\n`);
  }

  if (options.dryRun) {
    process.stdout.write("\nDry run — no migrations applied.\n");
    return;
  }

  for (const filename of pending) {
    const filepath = resolve(migrationsDir, filename);
    const content = readFileSync(filepath, "utf-8");

    process.stdout.write(`\nApplying ${filename}...\n`);

    try {
      await sql.unsafe(content);
      await recordMigration(filename);
      process.stdout.write(`  OK\n`);
    } catch (err) {
      process.stderr.write(`  FAILED: ${err instanceof Error ? err.message : String(err)}\n`);
      process.stderr.write(`\nMigration ${filename} failed. Stopping.\n`);
      process.exit(1);
    }
  }

  process.stdout.write("\nAll migrations applied successfully.\n");
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || command === "up") {
    const migrationsDir = args[1] || resolve(import.meta.dirname ?? ".", "../../migrations");
    const dryRun = args.includes("--dry-run");
    const targetIdx = args.indexOf("--target");
    const target = targetIdx >= 0 ? args[targetIdx + 1] : undefined;
    await runMigrations(migrationsDir, { dryRun, target });
  } else if (command === "status") {
    const applied = await getAppliedMigrations();
    if (applied.size === 0) {
      process.stdout.write("No migrations applied yet.\n");
    } else {
      process.stdout.write(`Applied migrations (${applied.size}):\n`);
      for (const f of applied) {
        process.stdout.write(`  ✓ ${f}\n`);
      }
    }
  } else if (command === "apply") {
    const filename = args[1];
    if (!filename) {
      process.stderr.write("Usage: tsx src/scripts/run-migration-neon.ts apply <filename.sql|filepath>\n");
      process.exit(1);
    }
    const resolved = filename.includes("/") ? resolve(filename) : resolve(import.meta.dirname ?? ".", "../../migrations", filename);
    const baseName = basename(resolved);

    const applied = await getAppliedMigrations();
    if (applied.has(baseName)) {
      process.stdout.write(`Migration ${baseName} already applied.\n`);
      return;
    }

    const content = readFileSync(resolved, "utf-8");
    process.stdout.write(`Applying ${baseName}...\n`);

    try {
      await sql.unsafe(content);
      await recordMigration(baseName);
      process.stdout.write("OK\n");
    } catch (err) {
      process.stderr.write(`FAILED: ${err instanceof Error ? err.message : String(err)}\n`);
      process.exit(1);
    }
  } else {
    process.stderr.write(`Usage: tsx src/scripts/run-migration-neon.ts [up|status|apply] [options]\n`);
    process.exit(1);
  }
}

main().catch((err) => {
  process.stderr.write(`Fatal: ${err instanceof Error ? err.message : String(err)}\n`);
  process.exit(1);
});