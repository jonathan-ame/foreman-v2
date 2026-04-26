import type { Logger } from "pino";
import type Stripe from "stripe";
import type { ApprovalAction, HireAgentRequest, HireAgentResponse, PaperclipAgent, PendingApproval } from "../../clients/paperclip/types.js";
import type { PaymentIntentResult, PaymentStatus } from "../../clients/stripe/types.js";
import type { OpenClawAgentRecord, OpenClawAgentSpec } from "../../clients/openclaw/types.js";
import type { ComposioSession } from "../../clients/composio/types.js";
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
  listAgents(companyId: string): Promise<PaperclipAgent[]>;
  triggerHeartbeat(agentId: string): Promise<{ ok: boolean; runId?: string }>;
  getAgentInbox(agentId: string): Promise<unknown[]>;
  createIssue(companyId: string, input: Record<string, unknown>): Promise<unknown>;
  listIssues(companyId: string, filters?: { status?: string; assigneeAgentId?: string }): Promise<unknown[]>;
  getIssue(issueId: string): Promise<unknown>;
  updateIssue(issueId: string, patch: Record<string, unknown>): Promise<unknown>;
  listIssueComments(issueId: string): Promise<unknown[]>;
  addIssueComment(issueId: string, body: string): Promise<unknown>;
  listIssueDocuments(issueId: string): Promise<unknown[]>;
  getIssueDocument(issueId: string, key: string): Promise<unknown>;
  listProjects(companyId: string): Promise<unknown[]>;
  createProject(companyId: string, input: Record<string, unknown>): Promise<unknown>;
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
  setMcpServer(name: string, config: Record<string, unknown>): Promise<void>;
  unsetMcpServer(name: string): Promise<void>;
  listMcpServers(): Promise<Record<string, unknown>>;
}

export interface StripeClientLike {
  getSubscriptionStatus(stripeCustomerId: string): Promise<PaymentStatus>;
  hasFailedPaymentSince(stripeCustomerId: string, since: Date): Promise<boolean>;
  getPrepaidBalanceCents(stripeCustomerId: string): Promise<number>;
  createSubscription(stripeCustomerId: string, productId: string): Promise<string>;
  cancelSubscription(subscriptionId: string): Promise<void>;
  createPaymentIntent(stripeCustomerId: string, amountCents: number): Promise<PaymentIntentResult>;
  constructWebhookEvent(payload: string, signature: string, webhookSecret: string): Stripe.Event;
  createCustomer(email: string, name: string, internalId: string): Promise<Stripe.Customer>;
  createCheckoutSession(stripeCustomerId: string, priceId: string, successUrl: string, cancelUrl: string): Promise<Stripe.Checkout.Session>;
  createPortalSession(stripeCustomerId: string, returnUrl: string): Promise<Stripe.BillingPortal.Session>;
}

export interface ComposioClientLike {
  isConfigured: boolean;
  createSession(userId: string, options?: { toolkits?: string[] }): Promise<ComposioSession>;
  ping(): Promise<{ ok: boolean }>;
}

export interface StepContext {
  input: ProvisionInput;
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
    composio: ComposioClientLike;
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