import type { Logger } from "pino";
import type Stripe from "stripe";
import type { ApprovalAction, HireAgentRequest, HireAgentResponse, PaperclipAgent, PendingApproval } from "../../clients/paperclip/types.js";
import type { OpenClawAgentRecord, OpenClawAgentSpec } from "../../clients/openclaw/types.js";
import type { PaymentIntentResult, PaymentStatus } from "../../clients/stripe/types.js";
import type { SupabaseClient } from "../../db/supabase.js";
import type { ProvisionInput } from "../types.js";

export interface PaperclipClientLike {
  hireAgent(companyId: string, request: HireAgentRequest): Promise<HireAgentResponse>;
  getAgent(agentId: string): Promise<PaperclipAgent>;
  patchAgent(agentId: string, patch: Partial<PaperclipAgent>): Promise<PaperclipAgent>;
  deleteAgent(agentId: string): Promise<void>;
  listPendingApprovals(companyId: string): Promise<PendingApproval[]>;
  getApproval(approvalId: string): Promise<PendingApproval>;
  actOnApproval(approvalId: string, action: ApprovalAction, body?: Record<string, unknown>): Promise<void>;
  ping(): Promise<{ ok: boolean; version?: string }>;
}

export interface OpenClawClientLike {
  addAgent(spec: OpenClawAgentSpec): Promise<OpenClawAgentRecord>;
  deleteAgent(agentId: string): Promise<void>;
  listAgents(): Promise<OpenClawAgentRecord[]>;
  getAgent(agentId: string): Promise<OpenClawAgentRecord | null>;
  reloadSecrets(): Promise<void>;
  restartGateway(): Promise<void>;
  readGatewayToken(): Promise<string>;
  gatewayStatus(): Promise<{ running: boolean; pid?: number; listening?: string }>;
}

export interface StripeClientLike {
  getSubscriptionStatus(stripeCustomerId: string): Promise<PaymentStatus>;
  hasFailedPaymentSince(stripeCustomerId: string, since: Date): Promise<boolean>;
  getPrepaidBalanceCents(stripeCustomerId: string): Promise<number>;
  createSubscription(stripeCustomerId: string, productId: string): Promise<string>;
  cancelSubscription(subscriptionId: string): Promise<void>;
  createPaymentIntent(stripeCustomerId: string, amountCents: number): Promise<PaymentIntentResult>;
  constructWebhookEvent(payload: string, signature: string, webhookSecret: string): Stripe.Event;
}

export interface StepContext {
  input: ProvisionInput;
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
  };
  db: SupabaseClient;
  logger: Logger;
  state: Record<string, unknown>;
}

export interface StepResult {
  ok: boolean;
  errorCode?: string;
  errorMessage?: string;
  data?: Record<string, unknown>;
}
