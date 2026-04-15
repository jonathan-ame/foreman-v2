# Foreman v2 Backend

This package is the orchestration backend for Foreman v2, providing the future service surface for provisioning, billing, and agent operations with a TypeScript-first foundation.

## Quickstart

1. Install dependencies: `pnpm install`
2. Copy environment template: `cp .env.example .env`
3. Start development server: `pnpm dev`

## Scripts

| Script | Description |
| --- | --- |
| `pnpm build` | Compile TypeScript into `dist/` |
| `pnpm dev` | Run server in watch mode |
| `pnpm start` | Run compiled server |
| `pnpm lint` | Lint `src/` TypeScript files |
| `pnpm test` | Run Vitest once |
| `pnpm typecheck` | Run strict TypeScript checks without emit |
| `pnpm cli -- ping` | Run CLI ping command |

See the related scope document: `../docs/specs/provision-foreman-agent-scope.md`.
