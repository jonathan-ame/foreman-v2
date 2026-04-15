import process from "node:process";

const [command] = process.argv.slice(2);

if (command === "ping") {
  process.stdout.write(
    `${JSON.stringify({ status: "ok", env: process.env.NODE_ENV ?? "development" })}\n`
  );
  process.exit(0);
}

process.stderr.write("Unknown command. Supported command: ping\n");
process.exit(1);
