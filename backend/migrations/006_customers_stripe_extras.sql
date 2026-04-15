ALTER TABLE customers
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_product_id TEXT;

ALTER TABLE customers
DROP CONSTRAINT IF EXISTS customers_current_tier_check;

ALTER TABLE customers
ADD CONSTRAINT customers_current_tier_check
CHECK (current_tier IS NULL OR current_tier IN ('tier_1', 'tier_2', 'tier_3', 'byok_platform'));

CREATE INDEX IF NOT EXISTS idx_customers_stripe_subscription_id
ON customers(stripe_subscription_id)
WHERE stripe_subscription_id IS NOT NULL;
