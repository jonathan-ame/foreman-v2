import { describe, it, expect } from 'vitest';
import { DATA_QUALITY_DIMENSIONS } from './validations';

describe('Data Quality Validation', () => {
  it('exports dimension definitions with required fields', () => {
    expect(DATA_QUALITY_DIMENSIONS.length).toBeGreaterThan(0);

    for (const dim of DATA_QUALITY_DIMENSIONS) {
      expect(dim.dimension).toBeTruthy();
      expect(dim.description).toBeTruthy();
      expect(Array.isArray(dim.checks)).toBe(true);

      for (const check of dim.checks) {
        expect(check.name).toBeTruthy();
        expect(check.description).toBeTruthy();
        expect(check.query).toBeTruthy();
        expect(['critical', 'warning', 'info']).toContain(check.severity);
      }
    }
  });
});
