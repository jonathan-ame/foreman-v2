ALTER TABLE customers
ADD COLUMN IF NOT EXISTS tokens_consumed_current_period_cents BIGINT,
ADD COLUMN IF NOT EXISTS tier_allowance_cents BIGINT;

COMMENT ON COLUMN customers.tokens_consumed_current_period_cents IS
'Metered token cost accumulated in the current billing period (cents-equivalent).';

COMMENT ON COLUMN customers.tier_allowance_cents IS
'Tier allowance ceiling for the current billing period (cents-equivalent).';
