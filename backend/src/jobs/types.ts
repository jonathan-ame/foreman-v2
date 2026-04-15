import type { AppDeps } from "../app-deps.js";

export type JobStatus = "ok" | "noop" | "error";

export interface JobResult {
  jobName: string;
  status: JobStatus;
  message: string;
  details?: Record<string, unknown>;
}

export interface JobDefinition {
  name: string;
  schedule: string;
  run: (deps: AppDeps) => Promise<JobResult>;
}
