type UsageTotals = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  total?: number;
};

type ModelCostRates = {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
};

const ONE_MILLION = 1_000_000;

const toRecord = (value: unknown): Record<string, unknown> =>
  value && typeof value === "object" ? (value as Record<string, unknown>) : {};

const numberOrZero = (value: unknown): number =>
  typeof value === "number" && Number.isFinite(value) ? value : 0;

const nonEmptyString = (value: unknown): string | null => {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
};

const normalizeModelCandidates = (providerId: unknown, modelId: unknown): Set<string> => {
  const normalized = new Set<string>();
  const providerClean =
    typeof providerId === "string" ? providerId.trim() : String(providerId ?? "").trim();
  const modelClean = typeof modelId === "string" ? modelId.trim() : String(modelId ?? "").trim();
  if (!providerClean || !modelClean) {
    return normalized;
  }
  const providerPrefix = `${providerClean}/`;
  const model = modelClean;
  normalized.add(model);
  if (model.startsWith(providerPrefix)) {
    normalized.add(model.slice(providerPrefix.length));
  } else {
    normalized.add(`${providerClean}/${model}`);
  }
  return normalized;
};

export const resolveModelCostRates = (
  config: unknown,
  providerId: unknown,
  modelId: unknown
): ModelCostRates | null => {
  const providerKey =
    typeof providerId === "string" ? providerId.trim() : String(providerId ?? "").trim();
  if (!providerKey) {
    return null;
  }
  const providers = toRecord(toRecord(toRecord(config).models).providers);
  const provider = toRecord(providers[providerKey]);
  const models = Array.isArray(provider.models) ? provider.models : [];
  const candidates = normalizeModelCandidates(providerKey, modelId);

  for (const entry of models) {
    const row = toRecord(entry);
    const id = nonEmptyString(row.id);
    if (!id || !candidates.has(id)) {
      continue;
    }
    const cost = toRecord(row.cost);
    return {
      input: numberOrZero(cost.input),
      output: numberOrZero(cost.output),
      cacheRead: numberOrZero(cost.cacheRead),
      cacheWrite: numberOrZero(cost.cacheWrite)
    };
  }

  return null;
};

export const calculateCostUsd = (usage: UsageTotals, rates: ModelCostRates | null): number => {
  if (!rates) {
    return 0;
  }
  const input = Math.max(0, numberOrZero(usage.input));
  const output = Math.max(0, numberOrZero(usage.output));
  const cacheRead = Math.max(0, numberOrZero(usage.cacheRead));
  const cacheWrite = Math.max(0, numberOrZero(usage.cacheWrite));
  return (
    (input * rates.input +
      output * rates.output +
      cacheRead * rates.cacheRead +
      cacheWrite * rates.cacheWrite) /
    ONE_MILLION
  );
};
