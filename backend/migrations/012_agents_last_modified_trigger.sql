CREATE OR REPLACE FUNCTION update_last_modified_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_modified_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS agents_updated_at ON agents;

CREATE TRIGGER agents_last_modified_at
  BEFORE UPDATE ON agents
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified_at_column();
