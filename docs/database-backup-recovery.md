# Backup & Recovery Strategy — Neon Database

**Project:** icy-breeze-57807060 (a.me)
**Region:** aws-us-east-1
**PostgreSQL Version:** 17

## Neon Built-in Protections

Neon provides several built-in backup and recovery features that do NOT require manual configuration:

### 1. Point-in-Time Recovery (PITR)
- Neon retains WAL data for **7 days** on the free tier, **30 days** on Pro.
- You can create a branch from any point within the retention window.
- **To recover:** `neon branches create --point-in-time "2026-04-24T12:00:00Z" --parent-branch production`
- Or via Console: Project → Branches → Create Branch → Select timestamp.

### 2. Branching (Zero-cost Snapshots)
- Neon branches are copy-on-write — they share data with the parent branch.
- **Pre-deployment branches:** Create a branch before running risky migrations, then delete it after validation.
- **Production branch:** `br-rapid-rice-amvycp3v` (the default/primary branch).

### 3. Automatic Storage Snapshots
- Neon takes periodic storage snapshots automatically.
- No manual backup scripts needed for basic disaster recovery.

## Manual Backup Procedures

### Schema Dump (recommended before migrations)
```bash
pg_dump "$NEON_DATABASE_URL" --schema-only --no-owner > supabase/backups/schema-$(date +%Y%m%d).sql
```

### Full Data Backup (for critical milestones)
```bash
pg_dump "$NEON_DATABASE_URL" --no-owner > supabase/backups/full-$(date +%Y%m%d).sql
```

### Single Table Backup
```bash
pg_dump "$NEON_DATABASE_URL" --table=customers --no-owner > supabase/backups/customers-$(date +%Y%m%d).sql
```

## Migration Disaster Recovery

If a migration goes wrong:

1. **Immediate rollback (within PITR window):**
   - Create a branch from the timestamp just before the migration.
   - Validate data on the branch.
   - Reset the production branch from the recovery branch, or connect the app to the recovery branch.

2. **SQL-level rollback:**
   - Each migration in `supabase/migrations/` should have a corresponding rollback in `supabase/migrations/_rollback/` (to be created as needed).
   - Use the migration runner: `pnpm migrate:apply <rollback-file>`.

3. **Schema version tracking:**
   - The `_migrations` table tracks all applied migrations.
   - Use `pnpm migrate:status` to inspect current state.

## Recommended Backup Schedule

| Event | Action | Retention |
|-------|--------|-----------|
| Pre-migration | Create Neon branch | Delete after migration verified |
| Weekly | `pg_dump --schema-only` | 4 weeks |
| Before major deployment | Full `pg_dump` | Indefinite (tagged) |
| CRM data import | `pg_dump crm_*` tables | Per import |

## Environment Variables for Backup

| Variable | Description |
|----------|-------------|
| `NEON_DATABASE_URL` | Neon connection string (replaces `DATABASE_URL` for migration runner) |
| `NEON_PROJECT_ID` | `icy-breeze-57807060` for API-based operations |

## Neon Console Access

- Dashboard: https://console.neon.tech/app/projects/icy-breeze-57807060
- Use the Neon API or CLI for branch operations.
- The `Neon_run_sql` MCP tool can also execute DDL/DML directly.

## Monitoring

- Neon provides built-in monitoring for compute, storage, and connection metrics.
- Alert on: compute auto-suspension (indicates idle), storage approaching limits, connection count spikes.
- The `health` schema in the database tracks application-level health metrics.