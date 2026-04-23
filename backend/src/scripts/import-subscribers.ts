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

const csvFile = process.argv[2];
if (!csvFile) {
  process.stderr.write("Usage: tsx src/scripts/import-subscribers.ts <subscribers.csv>\n");
  process.stderr.write("CSV format: email,name,company,use_case,source\n");
  process.stderr.write("  use_case: solopreneur | small_team | enterprise | technical | other\n");
  process.stderr.write("  source: homepage | blog | contact | other\n");
  process.stderr.write("Example: tsx src/scripts/import-subscribers.ts waitlist.csv\n");
  process.exit(1);
}

const VALID_USE_CASES = new Set(["solopreneur", "small_team", "enterprise", "technical", "other"]);
const VALID_SOURCES = new Set(["homepage", "blog", "contact", "other"]);

interface CsvRow {
  email: string;
  name: string;
  company: string;
  use_case: string;
  source: string;
}

function parseCsv(filePath: string): CsvRow[] {
  const content = readFileSync(resolve(filePath), "utf-8");
  const lines = content.trim().split("\n");
  if (lines.length === 0) {
    process.stderr.write("CSV file is empty\n");
    process.exit(1);
  }

  const headerLine = lines[0]!.toLowerCase().trim();
  const hasHeader = headerLine.includes("email");
  const startIdx = hasHeader ? 1 : 0;

  const rows: CsvRow[] = [];
  for (let i = startIdx; i < lines.length; i++) {
    const line = lines[i]?.trim() ?? "";
    if (!line) continue;

    const cols = line.split(",").map((c) => c.trim().replace(/^"|"$/g, ""));
    const email = cols[0] ?? "";
    if (!email.includes("@")) continue;

    const useCase = cols[3] ?? "other";
    const source = cols[4] ?? "other";

    rows.push({
      email,
      name: cols[1] ?? "",
      company: cols[2] ?? "",
      use_case: VALID_USE_CASES.has(useCase) ? useCase : "other",
      source: VALID_SOURCES.has(source) ? source : "other",
    });
  }

  return rows;
}

async function importSubscribers() {
  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!, {
    auth: { persistSession: false },
  });

  const rows = parseCsv(csvFile!);
  if (rows.length === 0) {
    process.stderr.write("No valid rows found in CSV\n");
    process.exit(1);
  }

  process.stdout.write(`Importing ${rows.length} subscribers...\n`);

  let imported = 0;
  let updated = 0;
  let failed = 0;
  const errors: string[] = [];

  for (const row of rows) {
    const { data: existing } = await supabase
      .from("email_subscribers")
      .select("id, unsubscribed_at")
      .eq("email", row.email)
      .maybeSingle();

    if (existing) {
      const ex = existing as { id: string; unsubscribed_at: string | null };
      const { error } = await supabase
        .from("email_subscribers")
        .update({
          name: row.name || null,
          company: row.company || null,
          use_case: row.use_case,
          source: row.source,
          unsubscribed_at: null,
        })
        .eq("id", ex.id);

      if (error) {
        failed++;
        errors.push(`${row.email}: ${error.message}`);
      } else {
        updated++;
      }
    } else {
      const { error } = await supabase.from("email_subscribers").insert({
        email: row.email,
        name: row.name || null,
        company: row.company || null,
        use_case: row.use_case,
        source: row.source,
      });

      if (error) {
        failed++;
        errors.push(`${row.email}: ${error.message}`);
      } else {
        imported++;
      }
    }
  }

  process.stdout.write(`\nImport complete:\n`);
  process.stdout.write(`  New subscribers: ${imported}\n`);
  process.stdout.write(`  Updated subscribers: ${updated}\n`);
  process.stdout.write(`  Failed: ${failed}\n`);

  if (errors.length > 0) {
    process.stderr.write(`\nErrors:\n${errors.join("\n")}\n`);
  }
}

importSubscribers();