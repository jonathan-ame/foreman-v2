# Credential Management — Foreman Phase 1 Infrastructure

## Architecture

Foreman uses a layered credential storage approach:

| Layer | Storage | Access | Use Case |
|-------|---------|--------|----------|
| **Local Development** | `.env` file (gitignored, chmod 600) | File system | Developer workstations |
| **Production** | Railway environment variables | Railway dashboard/API | Deployed services |
| **Database** | Supabase Vault (Phase 2) | SQL RPC | Application-level secrets |

### Credential Flow

```
.env (local) ──→ configure.sh ──→ ~/.openclaw/foreman.json5
                                    ↓
Railway env vars ──→ backend process ──→ config/env.ts (Zod validation)
                                        ↓
                                   config/secrets.ts (access control + audit)
                                        ↓
                                   clients/* (provider SDKs)
```

## Provider Credential Summary

| Provider | Variables | Classification | Rotation | Status |
|----------|-----------|----------------|----------|--------|
| **Railway** | `RAILWAY_API_KEY` | Restricted | 90 days | ✅ Available |
| **Stripe** | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, + price IDs | Restricted/Internal | 90-180 days | ✅ Available |
| **Supabase** | `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_ANON_KEY` | Internal/Restricted | 90-180 days | ✅ Available |
| **Cloudflare** | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ZONE_ID`, + LB IDs | Restricted/Internal | 90 days | ✅ Available |
| **Resend** | `RESEND_API_KEY`, `EMAIL_FROM`, `CEO_REVIEW_EMAIL` | Restricted/Public | 90 days | ⏳ Deferred (FORA-42) |
| **Sentry** | `SENTRY_DSN` | Internal | N/A | ⏳ Deferred (FORA-42) |
| **OpenRouter** | `OPENROUTER_API_KEY` | Restricted | 90 days | ✅ Available |
| **DashScope** | `DASHSCOPE_SG_KEY`, `DASHSCOPE_US_KEY` | Restricted | 90 days | ✅ Available |

## Security Classifications

- **Public** — Can be shared openly (payment links, mode selectors)
- **Internal** — Should not be exposed publicly but low risk if leaked (project URLs, account IDs)
- **Restricted** — Must never be exposed (API keys, secrets, tokens)

## Access Control

### Module API

All credential access should go through `config/secrets.ts`:

```typescript
import { resolveSecret, redactSecret } from "../config/secrets.js";

// Resolve with audit logging
const result = resolveSecret("STRIPE_SECRET_KEY", "payment-handler");
if (!result.resolved) {
  // Handle missing secret
}

// Redact for safe logging
console.log(`Using key: ${redactSecret(result.value)}`);
// Output: Using key: sk_l***mnop

// Check credential status
import { getCredentialStatus, getDeferredSecrets } from "../config/secrets.js";
const status = getCredentialStatus();
const deferred = getDeferredSecrets();
```

### Validation

- **Startup validation**: `config/env.ts` uses Zod to validate required secrets at boot
- **Runtime validation**: `config/secrets.ts` provides `validateRequiredSecrets()` for health checks
- **Provider validation**: `validateProviderSecrets("stripe")` checks all Stripe credentials

## Credential Rotation

### Using the Rotation Script

```bash
# Check which credentials need rotation
./scripts/rotate-credentials.sh --check

# Check a specific provider
./scripts/rotate-credentials.sh stripe --check

# Rotate credentials (interactive)
./scripts/rotate-credentials.sh stripe

# Dry run (show what would be rotated)
./scripts/rotate-credentials.sh stripe --dry-run
```

### Rotation Tracking

Rotation dates are tracked in `state/credential-rotation-dates.json`:

```json
{
  "STRIPE_SECRET_KEY": "2026-04-21",
  "CLOUDFLARE_API_TOKEN": "2026-04-20"
}
```

### After Rotation

1. Update `.env` locally (script handles this)
2. Update Railway environment variables via [Railway Dashboard](https://railway.app/dashboard)
3. Run `pnpm run configure` to sync to OpenClaw config
4. Redeploy: `railway up` or push to main branch

## Railway Production Secrets

Railway encrypts environment variables at rest. To manage:

1. **Via Dashboard**: Project → Service → Variables tab
2. **Via CLI**: `railway variables set STRIPE_SECRET_KEY=sk_live_...`
3. **Via API**: Use `RAILWAY_API_KEY` for programmatic access

### Important Notes

- Never commit `.env` to git (it's in `.gitignore`)
- Railway variables override `.env` in production
- Use `STRIPE_MODE=test` for staging environments
- `SUPABASE_SERVICE_KEY` bypasses RLS — use only server-side

## Deferred Credentials

The following credentials are blocked by [FORA-42](/FORA/issues/FORA-42):

- **Resend**: `RESEND_API_KEY` — CEO must obtain from resend.com
- **Sentry**: `SENTRY_DSN` — CEO must create project at sentry.io

Once these are obtained:
1. Add to `.env` file
2. Update Railway environment variables
3. Run `pnpm run configure`
4. The `email` client and `sentry` config will automatically activate

## Audit Trail

The `config/secrets.ts` module logs all secret access events:

```typescript
import { getAccessLog } from "../config/secrets.js";
const log = getAccessLog(50);
// Returns: [{ key: "STRIPE_SECRET_KEY", timestamp: "...", source: "payment-handler" }]
```

Access events are stored in-memory (not persisted to disk in Phase 1).
Phase 2 will persist audit logs to Supabase.

## Future Enhancements (Phase 2)

- [ ] Supabase Vault for database-stored secrets
- [ ] Persistent audit log table in Supabase
- [ ] Automatic rotation via Railway API + provider APIs
- [ ] Secret scanning in CI (detect leaked keys)
- [ ] HashiCorp Vault for enterprise-grade secret management
- [ ] Per-tenant credential isolation
