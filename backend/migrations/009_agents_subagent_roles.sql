ALTER TABLE agents
DROP CONSTRAINT IF EXISTS agents_role_check;

ALTER TABLE agents
ADD CONSTRAINT agents_role_check
CHECK (role IN ('ceo', 'marketing_analyst'));
