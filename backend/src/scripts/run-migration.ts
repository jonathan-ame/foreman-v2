import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import process from "node:process";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  process.stderr.write("SUPABASE_URL and SUPABASE_SERVICE_KEY are required\n");
  process.exit(1);
}

const migrationFile = process.argv[2];
if (!migrationFile) {
  process.stderr.write("Usage: tsx src/scripts/run-migration.ts <migration-file.sql>\n");
  process.exit(1);
}

const resolvedPath = resolve(migrationFile);
const sql = readFileSync(resolvedPath, "utf-8");

async function runMigration() {
  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!, {
    auth: { persistSession: false }
  });

  const { error } = await supabase.rpc("exec_sql", { sql_string: sql });

  if (error) {
    if (error.message?.includes("function") && error.message?.includes("does not exist")) {
      process.stderr.write("exec_sql RPC not available. Apply the migration manually via the Supabase SQL editor:\n");
      process.stderr.write(`  File: ${migrationFile}\n`);
      process.exit(1);
    }
    process.stderr.write(`Migration failed: ${error.message}\n`);
    process.exit(1);
  }

  process.stdout.write("Migration applied successfully\n");
}

runMigration();
