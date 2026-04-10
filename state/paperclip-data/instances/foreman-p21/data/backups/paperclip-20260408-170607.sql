-- Paperclip database backup
-- Created: 2026-04-08T23:06:07.151Z

BEGIN;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
SET LOCAL session_replication_role = replica;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
SET LOCAL client_min_messages = warning;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Sequences
DROP SEQUENCE IF EXISTS "public"."heartbeat_run_events_id_seq" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE SEQUENCE "public"."heartbeat_run_events_id_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 NO CYCLE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.account
DROP TABLE IF EXISTS "public"."account" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."account" (
  "id" text NOT NULL,
  "account_id" text NOT NULL,
  "provider_id" text NOT NULL,
  "user_id" text NOT NULL,
  "access_token" text,
  "refresh_token" text,
  "id_token" text,
  "access_token_expires_at" timestamp with time zone,
  "refresh_token_expires_at" timestamp with time zone,
  "scope" text,
  "password" text,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.activity_log
DROP TABLE IF EXISTS "public"."activity_log" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."activity_log" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "actor_type" text DEFAULT 'system'::text NOT NULL,
  "actor_id" text NOT NULL,
  "action" text NOT NULL,
  "entity_type" text NOT NULL,
  "entity_id" text NOT NULL,
  "agent_id" uuid,
  "details" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "run_id" uuid,
  CONSTRAINT "activity_log_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agent_api_keys
DROP TABLE IF EXISTS "public"."agent_api_keys" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agent_api_keys" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "agent_id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "name" text NOT NULL,
  "key_hash" text NOT NULL,
  "last_used_at" timestamp with time zone,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "agent_api_keys_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agent_config_revisions
DROP TABLE IF EXISTS "public"."agent_config_revisions" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agent_config_revisions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "source" text DEFAULT 'patch'::text NOT NULL,
  "rolled_back_from_revision_id" uuid,
  "changed_keys" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "before_config" jsonb NOT NULL,
  "after_config" jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "agent_config_revisions_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agent_runtime_state
DROP TABLE IF EXISTS "public"."agent_runtime_state" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agent_runtime_state" (
  "agent_id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "adapter_type" text NOT NULL,
  "session_id" text,
  "state_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "last_run_id" uuid,
  "last_run_status" text,
  "total_input_tokens" bigint DEFAULT 0 NOT NULL,
  "total_output_tokens" bigint DEFAULT 0 NOT NULL,
  "total_cached_input_tokens" bigint DEFAULT 0 NOT NULL,
  "total_cost_cents" bigint DEFAULT 0 NOT NULL,
  "last_error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "agent_runtime_state_pkey" PRIMARY KEY ("agent_id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agent_task_sessions
DROP TABLE IF EXISTS "public"."agent_task_sessions" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agent_task_sessions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "adapter_type" text NOT NULL,
  "task_key" text NOT NULL,
  "session_params_json" jsonb,
  "session_display_id" text,
  "last_run_id" uuid,
  "last_error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "agent_task_sessions_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agent_wakeup_requests
DROP TABLE IF EXISTS "public"."agent_wakeup_requests" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agent_wakeup_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "source" text NOT NULL,
  "trigger_detail" text,
  "reason" text,
  "payload" jsonb,
  "status" text DEFAULT 'queued'::text NOT NULL,
  "coalesced_count" integer DEFAULT 0 NOT NULL,
  "requested_by_actor_type" text,
  "requested_by_actor_id" text,
  "idempotency_key" text,
  "run_id" uuid,
  "requested_at" timestamp with time zone DEFAULT now() NOT NULL,
  "claimed_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "agent_wakeup_requests_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.agents
DROP TABLE IF EXISTS "public"."agents" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."agents" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "name" text NOT NULL,
  "role" text DEFAULT 'general'::text NOT NULL,
  "title" text,
  "status" text DEFAULT 'idle'::text NOT NULL,
  "reports_to" uuid,
  "capabilities" text,
  "adapter_type" text DEFAULT 'process'::text NOT NULL,
  "adapter_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "budget_monthly_cents" integer DEFAULT 0 NOT NULL,
  "spent_monthly_cents" integer DEFAULT 0 NOT NULL,
  "last_heartbeat_at" timestamp with time zone,
  "metadata" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "runtime_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "permissions" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "icon" text,
  "pause_reason" text,
  "paused_at" timestamp with time zone,
  CONSTRAINT "agents_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.approval_comments
DROP TABLE IF EXISTS "public"."approval_comments" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."approval_comments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "approval_id" uuid NOT NULL,
  "author_agent_id" uuid,
  "author_user_id" text,
  "body" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "approval_comments_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.approvals
DROP TABLE IF EXISTS "public"."approvals" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."approvals" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "type" text NOT NULL,
  "requested_by_agent_id" uuid,
  "requested_by_user_id" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "payload" jsonb NOT NULL,
  "decision_note" text,
  "decided_by_user_id" text,
  "decided_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "approvals_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.assets
DROP TABLE IF EXISTS "public"."assets" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."assets" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "provider" text NOT NULL,
  "object_key" text NOT NULL,
  "content_type" text NOT NULL,
  "byte_size" integer NOT NULL,
  "sha256" text NOT NULL,
  "original_filename" text,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "assets_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.board_api_keys
DROP TABLE IF EXISTS "public"."board_api_keys" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."board_api_keys" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" text NOT NULL,
  "name" text NOT NULL,
  "key_hash" text NOT NULL,
  "last_used_at" timestamp with time zone,
  "revoked_at" timestamp with time zone,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "board_api_keys_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.budget_incidents
DROP TABLE IF EXISTS "public"."budget_incidents" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."budget_incidents" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "policy_id" uuid NOT NULL,
  "scope_type" text NOT NULL,
  "scope_id" uuid NOT NULL,
  "metric" text NOT NULL,
  "window_kind" text NOT NULL,
  "window_start" timestamp with time zone NOT NULL,
  "window_end" timestamp with time zone NOT NULL,
  "threshold_type" text NOT NULL,
  "amount_limit" integer NOT NULL,
  "amount_observed" integer NOT NULL,
  "status" text DEFAULT 'open'::text NOT NULL,
  "approval_id" uuid,
  "resolved_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "budget_incidents_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.budget_policies
DROP TABLE IF EXISTS "public"."budget_policies" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."budget_policies" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "scope_type" text NOT NULL,
  "scope_id" uuid NOT NULL,
  "metric" text DEFAULT 'billed_cents'::text NOT NULL,
  "window_kind" text NOT NULL,
  "amount" integer DEFAULT 0 NOT NULL,
  "warn_percent" integer DEFAULT 80 NOT NULL,
  "hard_stop_enabled" boolean DEFAULT true NOT NULL,
  "notify_enabled" boolean DEFAULT true NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_by_user_id" text,
  "updated_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "budget_policies_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.cli_auth_challenges
DROP TABLE IF EXISTS "public"."cli_auth_challenges" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."cli_auth_challenges" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "secret_hash" text NOT NULL,
  "command" text NOT NULL,
  "client_name" text,
  "requested_access" text DEFAULT 'board'::text NOT NULL,
  "requested_company_id" uuid,
  "pending_key_hash" text NOT NULL,
  "pending_key_name" text NOT NULL,
  "approved_by_user_id" text,
  "board_api_key_id" uuid,
  "approved_at" timestamp with time zone,
  "cancelled_at" timestamp with time zone,
  "expires_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "cli_auth_challenges_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.companies
DROP TABLE IF EXISTS "public"."companies" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."companies" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "status" text DEFAULT 'active'::text NOT NULL,
  "budget_monthly_cents" integer DEFAULT 0 NOT NULL,
  "spent_monthly_cents" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "issue_prefix" text DEFAULT 'PAP'::text NOT NULL,
  "issue_counter" integer DEFAULT 0 NOT NULL,
  "require_board_approval_for_new_agents" boolean DEFAULT true NOT NULL,
  "brand_color" text,
  "pause_reason" text,
  "paused_at" timestamp with time zone,
  "feedback_data_sharing_enabled" boolean DEFAULT false NOT NULL,
  "feedback_data_sharing_consent_at" timestamp with time zone,
  "feedback_data_sharing_consent_by_user_id" text,
  "feedback_data_sharing_terms_version" text,
  CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.company_logos
DROP TABLE IF EXISTS "public"."company_logos" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."company_logos" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "asset_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "company_logos_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.company_memberships
DROP TABLE IF EXISTS "public"."company_memberships" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."company_memberships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "principal_type" text NOT NULL,
  "principal_id" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "membership_role" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "company_memberships_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.company_secret_versions
DROP TABLE IF EXISTS "public"."company_secret_versions" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."company_secret_versions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "secret_id" uuid NOT NULL,
  "version" integer NOT NULL,
  "material" jsonb NOT NULL,
  "value_sha256" text NOT NULL,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revoked_at" timestamp with time zone,
  CONSTRAINT "company_secret_versions_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.company_secrets
DROP TABLE IF EXISTS "public"."company_secrets" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."company_secrets" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "name" text NOT NULL,
  "provider" text DEFAULT 'local_encrypted'::text NOT NULL,
  "external_ref" text,
  "latest_version" integer DEFAULT 1 NOT NULL,
  "description" text,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "company_secrets_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.company_skills
DROP TABLE IF EXISTS "public"."company_skills" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."company_skills" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "key" text NOT NULL,
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "markdown" text NOT NULL,
  "source_type" text DEFAULT 'local_path'::text NOT NULL,
  "source_locator" text,
  "source_ref" text,
  "trust_level" text DEFAULT 'markdown_only'::text NOT NULL,
  "compatibility" text DEFAULT 'compatible'::text NOT NULL,
  "file_inventory" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "metadata" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "company_skills_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.cost_events
DROP TABLE IF EXISTS "public"."cost_events" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."cost_events" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "issue_id" uuid,
  "project_id" uuid,
  "goal_id" uuid,
  "billing_code" text,
  "provider" text NOT NULL,
  "model" text NOT NULL,
  "input_tokens" integer DEFAULT 0 NOT NULL,
  "output_tokens" integer DEFAULT 0 NOT NULL,
  "cost_cents" integer NOT NULL,
  "occurred_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "heartbeat_run_id" uuid,
  "biller" text DEFAULT 'unknown'::text NOT NULL,
  "billing_type" text DEFAULT 'unknown'::text NOT NULL,
  "cached_input_tokens" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "cost_events_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.document_revisions
DROP TABLE IF EXISTS "public"."document_revisions" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."document_revisions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "document_id" uuid NOT NULL,
  "revision_number" integer NOT NULL,
  "body" text NOT NULL,
  "change_summary" text,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "title" text,
  "format" text DEFAULT 'markdown'::text NOT NULL,
  "created_by_run_id" uuid,
  CONSTRAINT "document_revisions_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.documents
DROP TABLE IF EXISTS "public"."documents" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."documents" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "title" text,
  "format" text DEFAULT 'markdown'::text NOT NULL,
  "latest_body" text NOT NULL,
  "latest_revision_id" uuid,
  "latest_revision_number" integer DEFAULT 1 NOT NULL,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "updated_by_agent_id" uuid,
  "updated_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.execution_workspaces
DROP TABLE IF EXISTS "public"."execution_workspaces" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."execution_workspaces" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "project_workspace_id" uuid,
  "source_issue_id" uuid,
  "mode" text NOT NULL,
  "strategy_type" text NOT NULL,
  "name" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "cwd" text,
  "repo_url" text,
  "base_ref" text,
  "branch_name" text,
  "provider_type" text DEFAULT 'local_fs'::text NOT NULL,
  "provider_ref" text,
  "derived_from_execution_workspace_id" uuid,
  "last_used_at" timestamp with time zone DEFAULT now() NOT NULL,
  "opened_at" timestamp with time zone DEFAULT now() NOT NULL,
  "closed_at" timestamp with time zone,
  "cleanup_eligible_at" timestamp with time zone,
  "cleanup_reason" text,
  "metadata" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "execution_workspaces_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.feedback_exports
DROP TABLE IF EXISTS "public"."feedback_exports" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."feedback_exports" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "feedback_vote_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "project_id" uuid,
  "author_user_id" text NOT NULL,
  "target_type" text NOT NULL,
  "target_id" text NOT NULL,
  "vote" text NOT NULL,
  "status" text DEFAULT 'local_only'::text NOT NULL,
  "destination" text,
  "export_id" text,
  "consent_version" text,
  "schema_version" text DEFAULT 'paperclip-feedback-envelope-v2'::text NOT NULL,
  "bundle_version" text DEFAULT 'paperclip-feedback-bundle-v2'::text NOT NULL,
  "payload_version" text DEFAULT 'paperclip-feedback-v1'::text NOT NULL,
  "payload_digest" text,
  "payload_snapshot" jsonb,
  "target_summary" jsonb NOT NULL,
  "redaction_summary" jsonb,
  "attempt_count" integer DEFAULT 0 NOT NULL,
  "last_attempted_at" timestamp with time zone,
  "exported_at" timestamp with time zone,
  "failure_reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "feedback_exports_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.feedback_votes
DROP TABLE IF EXISTS "public"."feedback_votes" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."feedback_votes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "target_type" text NOT NULL,
  "target_id" text NOT NULL,
  "author_user_id" text NOT NULL,
  "vote" text NOT NULL,
  "reason" text,
  "shared_with_labs" boolean DEFAULT false NOT NULL,
  "shared_at" timestamp with time zone,
  "consent_version" text,
  "redaction_summary" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "feedback_votes_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.finance_events
DROP TABLE IF EXISTS "public"."finance_events" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."finance_events" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid,
  "issue_id" uuid,
  "project_id" uuid,
  "goal_id" uuid,
  "heartbeat_run_id" uuid,
  "cost_event_id" uuid,
  "billing_code" text,
  "description" text,
  "event_kind" text NOT NULL,
  "direction" text DEFAULT 'debit'::text NOT NULL,
  "biller" text NOT NULL,
  "provider" text,
  "execution_adapter_type" text,
  "pricing_tier" text,
  "region" text,
  "model" text,
  "quantity" integer,
  "unit" text,
  "amount_cents" integer NOT NULL,
  "currency" text DEFAULT 'USD'::text NOT NULL,
  "estimated" boolean DEFAULT false NOT NULL,
  "external_invoice_id" text,
  "metadata_json" jsonb,
  "occurred_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "finance_events_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.goals
DROP TABLE IF EXISTS "public"."goals" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."goals" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "level" text DEFAULT 'task'::text NOT NULL,
  "status" text DEFAULT 'planned'::text NOT NULL,
  "parent_id" uuid,
  "owner_agent_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "goals_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.heartbeat_run_events
DROP TABLE IF EXISTS "public"."heartbeat_run_events" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."heartbeat_run_events" (
  "id" bigint DEFAULT nextval('heartbeat_run_events_id_seq'::regclass) NOT NULL,
  "company_id" uuid NOT NULL,
  "run_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "seq" integer NOT NULL,
  "event_type" text NOT NULL,
  "stream" text,
  "level" text,
  "color" text,
  "message" text,
  "payload" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "heartbeat_run_events_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.heartbeat_runs
DROP TABLE IF EXISTS "public"."heartbeat_runs" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."heartbeat_runs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "agent_id" uuid NOT NULL,
  "invocation_source" text DEFAULT 'on_demand'::text NOT NULL,
  "status" text DEFAULT 'queued'::text NOT NULL,
  "started_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "error" text,
  "external_run_id" text,
  "context_snapshot" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "trigger_detail" text,
  "wakeup_request_id" uuid,
  "exit_code" integer,
  "signal" text,
  "usage_json" jsonb,
  "result_json" jsonb,
  "session_id_before" text,
  "session_id_after" text,
  "log_store" text,
  "log_ref" text,
  "log_bytes" bigint,
  "log_sha256" text,
  "log_compressed" boolean DEFAULT false NOT NULL,
  "stdout_excerpt" text,
  "stderr_excerpt" text,
  "error_code" text,
  "process_pid" integer,
  "process_started_at" timestamp with time zone,
  "retry_of_run_id" uuid,
  "process_loss_retry_count" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "heartbeat_runs_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.instance_settings
DROP TABLE IF EXISTS "public"."instance_settings" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."instance_settings" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "singleton_key" text DEFAULT 'default'::text NOT NULL,
  "experimental" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "general" jsonb DEFAULT '{}'::jsonb NOT NULL,
  CONSTRAINT "instance_settings_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.instance_user_roles
DROP TABLE IF EXISTS "public"."instance_user_roles" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."instance_user_roles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" text NOT NULL,
  "role" text DEFAULT 'instance_admin'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "instance_user_roles_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.invites
DROP TABLE IF EXISTS "public"."invites" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."invites" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid,
  "invite_type" text DEFAULT 'company_join'::text NOT NULL,
  "token_hash" text NOT NULL,
  "allowed_join_types" text DEFAULT 'both'::text NOT NULL,
  "defaults_payload" jsonb,
  "expires_at" timestamp with time zone NOT NULL,
  "invited_by_user_id" text,
  "revoked_at" timestamp with time zone,
  "accepted_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "invites_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_approvals
DROP TABLE IF EXISTS "public"."issue_approvals" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_approvals" (
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "approval_id" uuid NOT NULL,
  "linked_by_agent_id" uuid,
  "linked_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_approvals_pk" PRIMARY KEY ("issue_id", "approval_id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_attachments
DROP TABLE IF EXISTS "public"."issue_attachments" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_attachments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "asset_id" uuid NOT NULL,
  "issue_comment_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_attachments_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_comments
DROP TABLE IF EXISTS "public"."issue_comments" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_comments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "author_agent_id" uuid,
  "author_user_id" text,
  "body" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by_run_id" uuid,
  CONSTRAINT "issue_comments_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_documents
DROP TABLE IF EXISTS "public"."issue_documents" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_documents" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "document_id" uuid NOT NULL,
  "key" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_documents_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_inbox_archives
DROP TABLE IF EXISTS "public"."issue_inbox_archives" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_inbox_archives" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "user_id" text NOT NULL,
  "archived_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_inbox_archives_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_labels
DROP TABLE IF EXISTS "public"."issue_labels" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_labels" (
  "issue_id" uuid NOT NULL,
  "label_id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_labels_pk" PRIMARY KEY ("issue_id", "label_id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_read_states
DROP TABLE IF EXISTS "public"."issue_read_states" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_read_states" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "issue_id" uuid NOT NULL,
  "user_id" text NOT NULL,
  "last_read_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_read_states_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issue_work_products
DROP TABLE IF EXISTS "public"."issue_work_products" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issue_work_products" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid,
  "issue_id" uuid NOT NULL,
  "execution_workspace_id" uuid,
  "runtime_service_id" uuid,
  "type" text NOT NULL,
  "provider" text NOT NULL,
  "external_id" text,
  "title" text NOT NULL,
  "url" text,
  "status" text NOT NULL,
  "review_state" text DEFAULT 'none'::text NOT NULL,
  "is_primary" boolean DEFAULT false NOT NULL,
  "health_status" text DEFAULT 'unknown'::text NOT NULL,
  "summary" text,
  "metadata" jsonb,
  "created_by_run_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "issue_work_products_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.issues
DROP TABLE IF EXISTS "public"."issues" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."issues" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid,
  "goal_id" uuid,
  "parent_id" uuid,
  "title" text NOT NULL,
  "description" text,
  "status" text DEFAULT 'backlog'::text NOT NULL,
  "priority" text DEFAULT 'medium'::text NOT NULL,
  "assignee_agent_id" uuid,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "request_depth" integer DEFAULT 0 NOT NULL,
  "billing_code" text,
  "started_at" timestamp with time zone,
  "completed_at" timestamp with time zone,
  "cancelled_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "issue_number" integer,
  "identifier" text,
  "hidden_at" timestamp with time zone,
  "checkout_run_id" uuid,
  "execution_run_id" uuid,
  "execution_agent_name_key" text,
  "execution_locked_at" timestamp with time zone,
  "assignee_user_id" text,
  "assignee_adapter_overrides" jsonb,
  "execution_workspace_settings" jsonb,
  "project_workspace_id" uuid,
  "execution_workspace_id" uuid,
  "execution_workspace_preference" text,
  "origin_kind" text DEFAULT 'manual'::text NOT NULL,
  "origin_id" text,
  "origin_run_id" text,
  CONSTRAINT "issues_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.join_requests
DROP TABLE IF EXISTS "public"."join_requests" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."join_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "invite_id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "request_type" text NOT NULL,
  "status" text DEFAULT 'pending_approval'::text NOT NULL,
  "request_ip" text NOT NULL,
  "requesting_user_id" text,
  "request_email_snapshot" text,
  "agent_name" text,
  "adapter_type" text,
  "capabilities" text,
  "agent_defaults_payload" jsonb,
  "created_agent_id" uuid,
  "approved_by_user_id" text,
  "approved_at" timestamp with time zone,
  "rejected_by_user_id" text,
  "rejected_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "claim_secret_hash" text,
  "claim_secret_expires_at" timestamp with time zone,
  "claim_secret_consumed_at" timestamp with time zone,
  CONSTRAINT "join_requests_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.labels
DROP TABLE IF EXISTS "public"."labels" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."labels" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "name" text NOT NULL,
  "color" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "labels_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_company_settings
DROP TABLE IF EXISTS "public"."plugin_company_settings" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_company_settings" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "plugin_id" uuid NOT NULL,
  "settings_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "last_error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  CONSTRAINT "plugin_company_settings_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_config
DROP TABLE IF EXISTS "public"."plugin_config" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_config" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "config_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "last_error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_config_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_entities
DROP TABLE IF EXISTS "public"."plugin_entities" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_entities" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "entity_type" text NOT NULL,
  "scope_kind" text NOT NULL,
  "scope_id" text,
  "external_id" text,
  "title" text,
  "status" text,
  "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_entities_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_job_runs
DROP TABLE IF EXISTS "public"."plugin_job_runs" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_job_runs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "job_id" uuid NOT NULL,
  "plugin_id" uuid NOT NULL,
  "trigger" text NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "duration_ms" integer,
  "error" text,
  "logs" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "started_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_job_runs_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_jobs
DROP TABLE IF EXISTS "public"."plugin_jobs" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_jobs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "job_key" text NOT NULL,
  "schedule" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "last_run_at" timestamp with time zone,
  "next_run_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_jobs_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_logs
DROP TABLE IF EXISTS "public"."plugin_logs" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_logs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "level" text DEFAULT 'info'::text NOT NULL,
  "message" text NOT NULL,
  "meta" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_logs_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_state
DROP TABLE IF EXISTS "public"."plugin_state" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_state" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "scope_kind" text NOT NULL,
  "scope_id" text,
  "namespace" text DEFAULT 'default'::text NOT NULL,
  "state_key" text NOT NULL,
  "value_json" jsonb NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_state_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugin_webhook_deliveries
DROP TABLE IF EXISTS "public"."plugin_webhook_deliveries" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugin_webhook_deliveries" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_id" uuid NOT NULL,
  "webhook_key" text NOT NULL,
  "external_id" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "duration_ms" integer,
  "error" text,
  "payload" jsonb NOT NULL,
  "headers" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "started_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugin_webhook_deliveries_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.plugins
DROP TABLE IF EXISTS "public"."plugins" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."plugins" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "plugin_key" text NOT NULL,
  "package_name" text NOT NULL,
  "package_path" text,
  "version" text NOT NULL,
  "api_version" integer DEFAULT 1 NOT NULL,
  "categories" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "manifest_json" jsonb NOT NULL,
  "status" text DEFAULT 'installed'::text NOT NULL,
  "install_order" integer,
  "last_error" text,
  "installed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "plugins_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.principal_permission_grants
DROP TABLE IF EXISTS "public"."principal_permission_grants" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."principal_permission_grants" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "principal_type" text NOT NULL,
  "principal_id" text NOT NULL,
  "permission_key" text NOT NULL,
  "scope" jsonb,
  "granted_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "principal_permission_grants_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.project_goals
DROP TABLE IF EXISTS "public"."project_goals" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."project_goals" (
  "project_id" uuid NOT NULL,
  "goal_id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "project_goals_project_id_goal_id_pk" PRIMARY KEY ("project_id", "goal_id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.project_workspaces
DROP TABLE IF EXISTS "public"."project_workspaces" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."project_workspaces" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "name" text NOT NULL,
  "cwd" text,
  "repo_url" text,
  "repo_ref" text,
  "metadata" jsonb,
  "is_primary" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "source_type" text DEFAULT 'local_path'::text NOT NULL,
  "default_ref" text,
  "visibility" text DEFAULT 'default'::text NOT NULL,
  "setup_command" text,
  "cleanup_command" text,
  "remote_provider" text,
  "remote_workspace_ref" text,
  "shared_workspace_key" text,
  CONSTRAINT "project_workspaces_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.projects
DROP TABLE IF EXISTS "public"."projects" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."projects" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "goal_id" uuid,
  "name" text NOT NULL,
  "description" text,
  "status" text DEFAULT 'backlog'::text NOT NULL,
  "lead_agent_id" uuid,
  "target_date" date,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "color" text,
  "archived_at" timestamp with time zone,
  "execution_workspace_policy" jsonb,
  "pause_reason" text,
  "paused_at" timestamp with time zone,
  CONSTRAINT "projects_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.routine_runs
DROP TABLE IF EXISTS "public"."routine_runs" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."routine_runs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "routine_id" uuid NOT NULL,
  "trigger_id" uuid,
  "source" text NOT NULL,
  "status" text DEFAULT 'received'::text NOT NULL,
  "triggered_at" timestamp with time zone DEFAULT now() NOT NULL,
  "idempotency_key" text,
  "trigger_payload" jsonb,
  "linked_issue_id" uuid,
  "coalesced_into_run_id" uuid,
  "failure_reason" text,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "routine_runs_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.routine_triggers
DROP TABLE IF EXISTS "public"."routine_triggers" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."routine_triggers" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "routine_id" uuid NOT NULL,
  "kind" text NOT NULL,
  "label" text,
  "enabled" boolean DEFAULT true NOT NULL,
  "cron_expression" text,
  "timezone" text,
  "next_run_at" timestamp with time zone,
  "last_fired_at" timestamp with time zone,
  "public_id" text,
  "secret_id" uuid,
  "signing_mode" text,
  "replay_window_sec" integer,
  "last_rotated_at" timestamp with time zone,
  "last_result" text,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "updated_by_agent_id" uuid,
  "updated_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "routine_triggers_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.routines
DROP TABLE IF EXISTS "public"."routines" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."routines" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "goal_id" uuid,
  "parent_issue_id" uuid,
  "title" text NOT NULL,
  "description" text,
  "assignee_agent_id" uuid NOT NULL,
  "priority" text DEFAULT 'medium'::text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "concurrency_policy" text DEFAULT 'coalesce_if_active'::text NOT NULL,
  "catch_up_policy" text DEFAULT 'skip_missed'::text NOT NULL,
  "created_by_agent_id" uuid,
  "created_by_user_id" text,
  "updated_by_agent_id" uuid,
  "updated_by_user_id" text,
  "last_triggered_at" timestamp with time zone,
  "last_enqueued_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "variables" jsonb DEFAULT '[]'::jsonb NOT NULL,
  CONSTRAINT "routines_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.session
DROP TABLE IF EXISTS "public"."session" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."session" (
  "id" text NOT NULL,
  "expires_at" timestamp with time zone NOT NULL,
  "token" text NOT NULL,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  "ip_address" text,
  "user_agent" text,
  "user_id" text NOT NULL,
  CONSTRAINT "session_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.user
DROP TABLE IF EXISTS "public"."user" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."user" (
  "id" text NOT NULL,
  "name" text NOT NULL,
  "email" text NOT NULL,
  "email_verified" boolean DEFAULT false NOT NULL,
  "image" text,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.verification
DROP TABLE IF EXISTS "public"."verification" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."verification" (
  "id" text NOT NULL,
  "identifier" text NOT NULL,
  "value" text NOT NULL,
  "expires_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  CONSTRAINT "verification_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.workspace_operations
DROP TABLE IF EXISTS "public"."workspace_operations" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."workspace_operations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "company_id" uuid NOT NULL,
  "execution_workspace_id" uuid,
  "heartbeat_run_id" uuid,
  "phase" text NOT NULL,
  "command" text,
  "cwd" text,
  "status" text DEFAULT 'running'::text NOT NULL,
  "exit_code" integer,
  "log_store" text,
  "log_ref" text,
  "log_bytes" bigint,
  "log_sha256" text,
  "log_compressed" boolean DEFAULT false NOT NULL,
  "stdout_excerpt" text,
  "stderr_excerpt" text,
  "metadata" jsonb,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "finished_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "workspace_operations_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Table: public.workspace_runtime_services
DROP TABLE IF EXISTS "public"."workspace_runtime_services" CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE TABLE "public"."workspace_runtime_services" (
  "id" uuid NOT NULL,
  "company_id" uuid NOT NULL,
  "project_id" uuid,
  "project_workspace_id" uuid,
  "issue_id" uuid,
  "scope_type" text NOT NULL,
  "scope_id" text,
  "service_name" text NOT NULL,
  "status" text NOT NULL,
  "lifecycle" text NOT NULL,
  "reuse_key" text,
  "command" text,
  "cwd" text,
  "port" integer,
  "url" text,
  "provider" text NOT NULL,
  "provider_ref" text,
  "owner_agent_id" uuid,
  "started_by_run_id" uuid,
  "last_used_at" timestamp with time zone DEFAULT now() NOT NULL,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "stopped_at" timestamp with time zone,
  "stop_policy" jsonb,
  "health_status" text DEFAULT 'unknown'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "execution_workspace_id" uuid,
  CONSTRAINT "workspace_runtime_services_pkey" PRIMARY KEY ("id")
);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Sequence ownership
ALTER SEQUENCE "public"."heartbeat_run_events_id_seq" OWNED BY "public"."heartbeat_run_events"."id";
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Foreign keys
ALTER TABLE "public"."account" ADD CONSTRAINT "account_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."activity_log" ADD CONSTRAINT "activity_log_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."activity_log" ADD CONSTRAINT "activity_log_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."activity_log" ADD CONSTRAINT "activity_log_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_api_keys" ADD CONSTRAINT "agent_api_keys_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_api_keys" ADD CONSTRAINT "agent_api_keys_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_config_revisions" ADD CONSTRAINT "agent_config_revisions_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_config_revisions" ADD CONSTRAINT "agent_config_revisions_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_config_revisions" ADD CONSTRAINT "agent_config_revisions_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_runtime_state" ADD CONSTRAINT "agent_runtime_state_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_runtime_state" ADD CONSTRAINT "agent_runtime_state_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_task_sessions" ADD CONSTRAINT "agent_task_sessions_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_task_sessions" ADD CONSTRAINT "agent_task_sessions_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_task_sessions" ADD CONSTRAINT "agent_task_sessions_last_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("last_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_wakeup_requests" ADD CONSTRAINT "agent_wakeup_requests_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agent_wakeup_requests" ADD CONSTRAINT "agent_wakeup_requests_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agents" ADD CONSTRAINT "agents_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."agents" ADD CONSTRAINT "agents_reports_to_agents_id_fk" FOREIGN KEY ("reports_to") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."approval_comments" ADD CONSTRAINT "approval_comments_approval_id_approvals_id_fk" FOREIGN KEY ("approval_id") REFERENCES "public"."approvals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."approval_comments" ADD CONSTRAINT "approval_comments_author_agent_id_agents_id_fk" FOREIGN KEY ("author_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."approval_comments" ADD CONSTRAINT "approval_comments_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."approvals" ADD CONSTRAINT "approvals_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."approvals" ADD CONSTRAINT "approvals_requested_by_agent_id_agents_id_fk" FOREIGN KEY ("requested_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."assets" ADD CONSTRAINT "assets_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."assets" ADD CONSTRAINT "assets_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."board_api_keys" ADD CONSTRAINT "board_api_keys_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."budget_incidents" ADD CONSTRAINT "budget_incidents_approval_id_approvals_id_fk" FOREIGN KEY ("approval_id") REFERENCES "public"."approvals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."budget_incidents" ADD CONSTRAINT "budget_incidents_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."budget_incidents" ADD CONSTRAINT "budget_incidents_policy_id_budget_policies_id_fk" FOREIGN KEY ("policy_id") REFERENCES "public"."budget_policies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."budget_policies" ADD CONSTRAINT "budget_policies_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cli_auth_challenges" ADD CONSTRAINT "cli_auth_challenges_approved_by_user_id_user_id_fk" FOREIGN KEY ("approved_by_user_id") REFERENCES "public"."user" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cli_auth_challenges" ADD CONSTRAINT "cli_auth_challenges_board_api_key_id_board_api_keys_id_fk" FOREIGN KEY ("board_api_key_id") REFERENCES "public"."board_api_keys" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cli_auth_challenges" ADD CONSTRAINT "cli_auth_challenges_requested_company_id_companies_id_fk" FOREIGN KEY ("requested_company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_logos" ADD CONSTRAINT "company_logos_asset_id_assets_id_fk" FOREIGN KEY ("asset_id") REFERENCES "public"."assets" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_logos" ADD CONSTRAINT "company_logos_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_memberships" ADD CONSTRAINT "company_memberships_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_secret_versions" ADD CONSTRAINT "company_secret_versions_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_secret_versions" ADD CONSTRAINT "company_secret_versions_secret_id_company_secrets_id_fk" FOREIGN KEY ("secret_id") REFERENCES "public"."company_secrets" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_secrets" ADD CONSTRAINT "company_secrets_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_secrets" ADD CONSTRAINT "company_secrets_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."company_skills" ADD CONSTRAINT "company_skills_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_heartbeat_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("heartbeat_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."cost_events" ADD CONSTRAINT "cost_events_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."document_revisions" ADD CONSTRAINT "document_revisions_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."document_revisions" ADD CONSTRAINT "document_revisions_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."document_revisions" ADD CONSTRAINT "document_revisions_created_by_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("created_by_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."document_revisions" ADD CONSTRAINT "document_revisions_document_id_documents_id_fk" FOREIGN KEY ("document_id") REFERENCES "public"."documents" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."documents" ADD CONSTRAINT "documents_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."documents" ADD CONSTRAINT "documents_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."documents" ADD CONSTRAINT "documents_updated_by_agent_id_agents_id_fk" FOREIGN KEY ("updated_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."execution_workspaces" ADD CONSTRAINT "execution_workspaces_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."execution_workspaces" ADD CONSTRAINT "execution_workspaces_derived_from_execution_workspace_id_execut" FOREIGN KEY ("derived_from_execution_workspace_id") REFERENCES "public"."execution_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."execution_workspaces" ADD CONSTRAINT "execution_workspaces_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."execution_workspaces" ADD CONSTRAINT "execution_workspaces_project_workspace_id_project_workspaces_id" FOREIGN KEY ("project_workspace_id") REFERENCES "public"."project_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."execution_workspaces" ADD CONSTRAINT "execution_workspaces_source_issue_id_issues_id_fk" FOREIGN KEY ("source_issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_exports" ADD CONSTRAINT "feedback_exports_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_exports" ADD CONSTRAINT "feedback_exports_feedback_vote_id_feedback_votes_id_fk" FOREIGN KEY ("feedback_vote_id") REFERENCES "public"."feedback_votes" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_exports" ADD CONSTRAINT "feedback_exports_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_exports" ADD CONSTRAINT "feedback_exports_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_votes" ADD CONSTRAINT "feedback_votes_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."feedback_votes" ADD CONSTRAINT "feedback_votes_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_cost_event_id_cost_events_id_fk" FOREIGN KEY ("cost_event_id") REFERENCES "public"."cost_events" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_heartbeat_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("heartbeat_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."finance_events" ADD CONSTRAINT "finance_events_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."goals" ADD CONSTRAINT "goals_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."goals" ADD CONSTRAINT "goals_owner_agent_id_agents_id_fk" FOREIGN KEY ("owner_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."goals" ADD CONSTRAINT "goals_parent_id_goals_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_run_events" ADD CONSTRAINT "heartbeat_run_events_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_run_events" ADD CONSTRAINT "heartbeat_run_events_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_run_events" ADD CONSTRAINT "heartbeat_run_events_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_runs" ADD CONSTRAINT "heartbeat_runs_agent_id_agents_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_runs" ADD CONSTRAINT "heartbeat_runs_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_runs" ADD CONSTRAINT "heartbeat_runs_retry_of_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("retry_of_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."heartbeat_runs" ADD CONSTRAINT "heartbeat_runs_wakeup_request_id_agent_wakeup_requests_id_fk" FOREIGN KEY ("wakeup_request_id") REFERENCES "public"."agent_wakeup_requests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."invites" ADD CONSTRAINT "invites_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_approvals" ADD CONSTRAINT "issue_approvals_approval_id_approvals_id_fk" FOREIGN KEY ("approval_id") REFERENCES "public"."approvals" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_approvals" ADD CONSTRAINT "issue_approvals_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_approvals" ADD CONSTRAINT "issue_approvals_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_approvals" ADD CONSTRAINT "issue_approvals_linked_by_agent_id_agents_id_fk" FOREIGN KEY ("linked_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_attachments" ADD CONSTRAINT "issue_attachments_asset_id_assets_id_fk" FOREIGN KEY ("asset_id") REFERENCES "public"."assets" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_attachments" ADD CONSTRAINT "issue_attachments_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_attachments" ADD CONSTRAINT "issue_attachments_issue_comment_id_issue_comments_id_fk" FOREIGN KEY ("issue_comment_id") REFERENCES "public"."issue_comments" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_attachments" ADD CONSTRAINT "issue_attachments_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_comments" ADD CONSTRAINT "issue_comments_author_agent_id_agents_id_fk" FOREIGN KEY ("author_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_comments" ADD CONSTRAINT "issue_comments_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_comments" ADD CONSTRAINT "issue_comments_created_by_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("created_by_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_comments" ADD CONSTRAINT "issue_comments_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_documents" ADD CONSTRAINT "issue_documents_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_documents" ADD CONSTRAINT "issue_documents_document_id_documents_id_fk" FOREIGN KEY ("document_id") REFERENCES "public"."documents" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_documents" ADD CONSTRAINT "issue_documents_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_inbox_archives" ADD CONSTRAINT "issue_inbox_archives_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_inbox_archives" ADD CONSTRAINT "issue_inbox_archives_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_labels" ADD CONSTRAINT "issue_labels_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_labels" ADD CONSTRAINT "issue_labels_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_labels" ADD CONSTRAINT "issue_labels_label_id_labels_id_fk" FOREIGN KEY ("label_id") REFERENCES "public"."labels" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_read_states" ADD CONSTRAINT "issue_read_states_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_read_states" ADD CONSTRAINT "issue_read_states_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_created_by_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("created_by_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_execution_workspace_id_execution_workspaces" FOREIGN KEY ("execution_workspace_id") REFERENCES "public"."execution_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issue_work_products" ADD CONSTRAINT "issue_work_products_runtime_service_id_workspace_runtime_servic" FOREIGN KEY ("runtime_service_id") REFERENCES "public"."workspace_runtime_services" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_assignee_agent_id_agents_id_fk" FOREIGN KEY ("assignee_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_checkout_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("checkout_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_execution_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("execution_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_execution_workspace_id_execution_workspaces_id_fk" FOREIGN KEY ("execution_workspace_id") REFERENCES "public"."execution_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_parent_id_issues_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."issues" ADD CONSTRAINT "issues_project_workspace_id_project_workspaces_id_fk" FOREIGN KEY ("project_workspace_id") REFERENCES "public"."project_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."join_requests" ADD CONSTRAINT "join_requests_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."join_requests" ADD CONSTRAINT "join_requests_created_agent_id_agents_id_fk" FOREIGN KEY ("created_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."join_requests" ADD CONSTRAINT "join_requests_invite_id_invites_id_fk" FOREIGN KEY ("invite_id") REFERENCES "public"."invites" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."labels" ADD CONSTRAINT "labels_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_company_settings" ADD CONSTRAINT "plugin_company_settings_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_company_settings" ADD CONSTRAINT "plugin_company_settings_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_config" ADD CONSTRAINT "plugin_config_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_entities" ADD CONSTRAINT "plugin_entities_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_job_runs" ADD CONSTRAINT "plugin_job_runs_job_id_plugin_jobs_id_fk" FOREIGN KEY ("job_id") REFERENCES "public"."plugin_jobs" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_job_runs" ADD CONSTRAINT "plugin_job_runs_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_jobs" ADD CONSTRAINT "plugin_jobs_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_logs" ADD CONSTRAINT "plugin_logs_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_state" ADD CONSTRAINT "plugin_state_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."plugin_webhook_deliveries" ADD CONSTRAINT "plugin_webhook_deliveries_plugin_id_plugins_id_fk" FOREIGN KEY ("plugin_id") REFERENCES "public"."plugins" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."principal_permission_grants" ADD CONSTRAINT "principal_permission_grants_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."project_goals" ADD CONSTRAINT "project_goals_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."project_goals" ADD CONSTRAINT "project_goals_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."project_goals" ADD CONSTRAINT "project_goals_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."project_workspaces" ADD CONSTRAINT "project_workspaces_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."project_workspaces" ADD CONSTRAINT "project_workspaces_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."projects" ADD CONSTRAINT "projects_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."projects" ADD CONSTRAINT "projects_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."projects" ADD CONSTRAINT "projects_lead_agent_id_agents_id_fk" FOREIGN KEY ("lead_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_runs" ADD CONSTRAINT "routine_runs_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_runs" ADD CONSTRAINT "routine_runs_linked_issue_id_issues_id_fk" FOREIGN KEY ("linked_issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_runs" ADD CONSTRAINT "routine_runs_routine_id_routines_id_fk" FOREIGN KEY ("routine_id") REFERENCES "public"."routines" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_runs" ADD CONSTRAINT "routine_runs_trigger_id_routine_triggers_id_fk" FOREIGN KEY ("trigger_id") REFERENCES "public"."routine_triggers" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_triggers" ADD CONSTRAINT "routine_triggers_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_triggers" ADD CONSTRAINT "routine_triggers_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_triggers" ADD CONSTRAINT "routine_triggers_routine_id_routines_id_fk" FOREIGN KEY ("routine_id") REFERENCES "public"."routines" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_triggers" ADD CONSTRAINT "routine_triggers_secret_id_company_secrets_id_fk" FOREIGN KEY ("secret_id") REFERENCES "public"."company_secrets" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routine_triggers" ADD CONSTRAINT "routine_triggers_updated_by_agent_id_agents_id_fk" FOREIGN KEY ("updated_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_assignee_agent_id_agents_id_fk" FOREIGN KEY ("assignee_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_created_by_agent_id_agents_id_fk" FOREIGN KEY ("created_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_goal_id_goals_id_fk" FOREIGN KEY ("goal_id") REFERENCES "public"."goals" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_parent_issue_id_issues_id_fk" FOREIGN KEY ("parent_issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."routines" ADD CONSTRAINT "routines_updated_by_agent_id_agents_id_fk" FOREIGN KEY ("updated_by_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."session" ADD CONSTRAINT "session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_operations" ADD CONSTRAINT "workspace_operations_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_operations" ADD CONSTRAINT "workspace_operations_execution_workspace_id_execution_workspace" FOREIGN KEY ("execution_workspace_id") REFERENCES "public"."execution_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_operations" ADD CONSTRAINT "workspace_operations_heartbeat_run_id_heartbeat_runs_id_fk" FOREIGN KEY ("heartbeat_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_execution_workspace_id_execution_wor" FOREIGN KEY ("execution_workspace_id") REFERENCES "public"."execution_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_owner_agent_id_agents_id_fk" FOREIGN KEY ("owner_agent_id") REFERENCES "public"."agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_project_workspace_id_project_workspa" FOREIGN KEY ("project_workspace_id") REFERENCES "public"."project_workspaces" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
ALTER TABLE "public"."workspace_runtime_services" ADD CONSTRAINT "workspace_runtime_services_started_by_run_id_heartbeat_runs_id_" FOREIGN KEY ("started_by_run_id") REFERENCES "public"."heartbeat_runs" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Unique constraints
ALTER TABLE "public"."plugin_state" ADD CONSTRAINT "plugin_state_unique_entry_idx" UNIQUE ("plugin_id", "scope_kind", "scope_id", "namespace", "state_key");
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Indexes
CREATE INDEX activity_log_company_created_idx ON public.activity_log USING btree (company_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX activity_log_entity_type_id_idx ON public.activity_log USING btree (entity_type, entity_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX activity_log_run_id_idx ON public.activity_log USING btree (run_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_api_keys_company_agent_idx ON public.agent_api_keys USING btree (company_id, agent_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_api_keys_key_hash_idx ON public.agent_api_keys USING btree (key_hash);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_config_revisions_agent_created_idx ON public.agent_config_revisions USING btree (agent_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_config_revisions_company_agent_created_idx ON public.agent_config_revisions USING btree (company_id, agent_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_runtime_state_company_agent_idx ON public.agent_runtime_state USING btree (company_id, agent_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_runtime_state_company_updated_idx ON public.agent_runtime_state USING btree (company_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX agent_task_sessions_company_agent_adapter_task_uniq ON public.agent_task_sessions USING btree (company_id, agent_id, adapter_type, task_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_task_sessions_company_agent_updated_idx ON public.agent_task_sessions USING btree (company_id, agent_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_task_sessions_company_task_updated_idx ON public.agent_task_sessions USING btree (company_id, task_key, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_wakeup_requests_agent_requested_idx ON public.agent_wakeup_requests USING btree (agent_id, requested_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_wakeup_requests_company_agent_status_idx ON public.agent_wakeup_requests USING btree (company_id, agent_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agent_wakeup_requests_company_requested_idx ON public.agent_wakeup_requests USING btree (company_id, requested_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agents_company_reports_to_idx ON public.agents USING btree (company_id, reports_to);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX agents_company_status_idx ON public.agents USING btree (company_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX approval_comments_approval_created_idx ON public.approval_comments USING btree (approval_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX approval_comments_approval_idx ON public.approval_comments USING btree (approval_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX approval_comments_company_idx ON public.approval_comments USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX approvals_company_status_type_idx ON public.approvals USING btree (company_id, status, type);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX assets_company_created_idx ON public.assets USING btree (company_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX assets_company_object_key_uq ON public.assets USING btree (company_id, object_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX assets_company_provider_idx ON public.assets USING btree (company_id, provider);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX board_api_keys_key_hash_idx ON public.board_api_keys USING btree (key_hash);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX board_api_keys_user_idx ON public.board_api_keys USING btree (user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX budget_incidents_company_scope_idx ON public.budget_incidents USING btree (company_id, scope_type, scope_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX budget_incidents_company_status_idx ON public.budget_incidents USING btree (company_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX budget_incidents_policy_window_threshold_idx ON public.budget_incidents USING btree (policy_id, window_start, threshold_type) WHERE (status <> 'dismissed'::text);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX budget_policies_company_scope_active_idx ON public.budget_policies USING btree (company_id, scope_type, scope_id, is_active);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX budget_policies_company_scope_metric_unique_idx ON public.budget_policies USING btree (company_id, scope_type, scope_id, metric, window_kind);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX budget_policies_company_window_idx ON public.budget_policies USING btree (company_id, window_kind, metric);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cli_auth_challenges_approved_by_idx ON public.cli_auth_challenges USING btree (approved_by_user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cli_auth_challenges_requested_company_idx ON public.cli_auth_challenges USING btree (requested_company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cli_auth_challenges_secret_hash_idx ON public.cli_auth_challenges USING btree (secret_hash);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX companies_issue_prefix_idx ON public.companies USING btree (issue_prefix);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_logos_asset_uq ON public.company_logos USING btree (asset_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_logos_company_uq ON public.company_logos USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_memberships_company_principal_unique_idx ON public.company_memberships USING btree (company_id, principal_type, principal_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_memberships_company_status_idx ON public.company_memberships USING btree (company_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_memberships_principal_status_idx ON public.company_memberships USING btree (principal_type, principal_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_secret_versions_secret_idx ON public.company_secret_versions USING btree (secret_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_secret_versions_secret_version_uq ON public.company_secret_versions USING btree (secret_id, version);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_secret_versions_value_sha256_idx ON public.company_secret_versions USING btree (value_sha256);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_secrets_company_idx ON public.company_secrets USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_secrets_company_name_uq ON public.company_secrets USING btree (company_id, name);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_secrets_company_provider_idx ON public.company_secrets USING btree (company_id, provider);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX company_skills_company_key_idx ON public.company_skills USING btree (company_id, key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX company_skills_company_name_idx ON public.company_skills USING btree (company_id, name);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cost_events_company_agent_occurred_idx ON public.cost_events USING btree (company_id, agent_id, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cost_events_company_biller_occurred_idx ON public.cost_events USING btree (company_id, biller, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cost_events_company_heartbeat_run_idx ON public.cost_events USING btree (company_id, heartbeat_run_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cost_events_company_occurred_idx ON public.cost_events USING btree (company_id, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX cost_events_company_provider_occurred_idx ON public.cost_events USING btree (company_id, provider, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX document_revisions_company_document_created_idx ON public.document_revisions USING btree (company_id, document_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX document_revisions_document_revision_uq ON public.document_revisions USING btree (document_id, revision_number);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX documents_company_created_idx ON public.documents USING btree (company_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX documents_company_updated_idx ON public.documents USING btree (company_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX execution_workspaces_company_branch_idx ON public.execution_workspaces USING btree (company_id, branch_name);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX execution_workspaces_company_last_used_idx ON public.execution_workspaces USING btree (company_id, last_used_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX execution_workspaces_company_project_status_idx ON public.execution_workspaces USING btree (company_id, project_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX execution_workspaces_company_project_workspace_status_idx ON public.execution_workspaces USING btree (company_id, project_workspace_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX execution_workspaces_company_source_issue_idx ON public.execution_workspaces USING btree (company_id, source_issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_exports_company_author_idx ON public.feedback_exports USING btree (company_id, author_user_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_exports_company_created_idx ON public.feedback_exports USING btree (company_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_exports_company_issue_idx ON public.feedback_exports USING btree (company_id, issue_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_exports_company_project_idx ON public.feedback_exports USING btree (company_id, project_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_exports_company_status_idx ON public.feedback_exports USING btree (company_id, status, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX feedback_exports_feedback_vote_idx ON public.feedback_exports USING btree (feedback_vote_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_votes_author_idx ON public.feedback_votes USING btree (author_user_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_votes_company_issue_idx ON public.feedback_votes USING btree (company_id, issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX feedback_votes_company_target_author_idx ON public.feedback_votes USING btree (company_id, target_type, target_id, author_user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX feedback_votes_issue_target_idx ON public.feedback_votes USING btree (issue_id, target_type, target_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_biller_occurred_idx ON public.finance_events USING btree (company_id, biller, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_cost_event_idx ON public.finance_events USING btree (company_id, cost_event_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_direction_occurred_idx ON public.finance_events USING btree (company_id, direction, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_heartbeat_run_idx ON public.finance_events USING btree (company_id, heartbeat_run_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_kind_occurred_idx ON public.finance_events USING btree (company_id, event_kind, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX finance_events_company_occurred_idx ON public.finance_events USING btree (company_id, occurred_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX goals_company_idx ON public.goals USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX heartbeat_run_events_company_created_idx ON public.heartbeat_run_events USING btree (company_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX heartbeat_run_events_company_run_idx ON public.heartbeat_run_events USING btree (company_id, run_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX heartbeat_run_events_run_seq_idx ON public.heartbeat_run_events USING btree (run_id, seq);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX heartbeat_runs_company_agent_started_idx ON public.heartbeat_runs USING btree (company_id, agent_id, started_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX instance_settings_singleton_key_idx ON public.instance_settings USING btree (singleton_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX instance_user_roles_role_idx ON public.instance_user_roles USING btree (role);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX instance_user_roles_user_role_unique_idx ON public.instance_user_roles USING btree (user_id, role);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX invites_company_invite_state_idx ON public.invites USING btree (company_id, invite_type, revoked_at, expires_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX invites_token_hash_unique_idx ON public.invites USING btree (token_hash);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_approvals_approval_idx ON public.issue_approvals USING btree (approval_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_approvals_company_idx ON public.issue_approvals USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_approvals_issue_idx ON public.issue_approvals USING btree (issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issue_attachments_asset_uq ON public.issue_attachments USING btree (asset_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_attachments_company_issue_idx ON public.issue_attachments USING btree (company_id, issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_attachments_issue_comment_idx ON public.issue_attachments USING btree (issue_comment_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_comments_company_author_issue_created_at_idx ON public.issue_comments USING btree (company_id, author_user_id, issue_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_comments_company_idx ON public.issue_comments USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_comments_company_issue_created_at_idx ON public.issue_comments USING btree (company_id, issue_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_comments_issue_idx ON public.issue_comments USING btree (issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issue_documents_company_issue_key_uq ON public.issue_documents USING btree (company_id, issue_id, key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_documents_company_issue_updated_idx ON public.issue_documents USING btree (company_id, issue_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issue_documents_document_uq ON public.issue_documents USING btree (document_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_inbox_archives_company_issue_idx ON public.issue_inbox_archives USING btree (company_id, issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issue_inbox_archives_company_issue_user_idx ON public.issue_inbox_archives USING btree (company_id, issue_id, user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_inbox_archives_company_user_idx ON public.issue_inbox_archives USING btree (company_id, user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_labels_company_idx ON public.issue_labels USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_labels_issue_idx ON public.issue_labels USING btree (issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_labels_label_idx ON public.issue_labels USING btree (label_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_read_states_company_issue_idx ON public.issue_read_states USING btree (company_id, issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issue_read_states_company_issue_user_idx ON public.issue_read_states USING btree (company_id, issue_id, user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_read_states_company_user_idx ON public.issue_read_states USING btree (company_id, user_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_work_products_company_execution_workspace_type_idx ON public.issue_work_products USING btree (company_id, execution_workspace_id, type);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_work_products_company_issue_type_idx ON public.issue_work_products USING btree (company_id, issue_id, type);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_work_products_company_provider_external_id_idx ON public.issue_work_products USING btree (company_id, provider, external_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issue_work_products_company_updated_idx ON public.issue_work_products USING btree (company_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_assignee_status_idx ON public.issues USING btree (company_id, assignee_agent_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_assignee_user_status_idx ON public.issues USING btree (company_id, assignee_user_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_execution_workspace_idx ON public.issues USING btree (company_id, execution_workspace_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_origin_idx ON public.issues USING btree (company_id, origin_kind, origin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_parent_idx ON public.issues USING btree (company_id, parent_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_project_idx ON public.issues USING btree (company_id, project_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_project_workspace_idx ON public.issues USING btree (company_id, project_workspace_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX issues_company_status_idx ON public.issues USING btree (company_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issues_identifier_idx ON public.issues USING btree (identifier);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX issues_open_routine_execution_uq ON public.issues USING btree (company_id, origin_kind, origin_id) WHERE ((origin_kind = 'routine_execution'::text) AND (origin_id IS NOT NULL) AND (hidden_at IS NULL) AND (execution_run_id IS NOT NULL) AND (status = ANY (ARRAY['backlog'::text, 'todo'::text, 'in_progress'::text, 'in_review'::text, 'blocked'::text])));
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX join_requests_company_status_type_created_idx ON public.join_requests USING btree (company_id, status, request_type, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX join_requests_invite_unique_idx ON public.join_requests USING btree (invite_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX labels_company_idx ON public.labels USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX labels_company_name_idx ON public.labels USING btree (company_id, name);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_company_settings_company_idx ON public.plugin_company_settings USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX plugin_company_settings_company_plugin_uq ON public.plugin_company_settings USING btree (company_id, plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_company_settings_plugin_idx ON public.plugin_company_settings USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX plugin_config_plugin_id_idx ON public.plugin_config USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX plugin_entities_external_idx ON public.plugin_entities USING btree (plugin_id, entity_type, external_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_entities_plugin_idx ON public.plugin_entities USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_entities_scope_idx ON public.plugin_entities USING btree (scope_kind, scope_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_entities_type_idx ON public.plugin_entities USING btree (entity_type);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_job_runs_job_idx ON public.plugin_job_runs USING btree (job_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_job_runs_plugin_idx ON public.plugin_job_runs USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_job_runs_status_idx ON public.plugin_job_runs USING btree (status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_jobs_next_run_idx ON public.plugin_jobs USING btree (next_run_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_jobs_plugin_idx ON public.plugin_jobs USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX plugin_jobs_unique_idx ON public.plugin_jobs USING btree (plugin_id, job_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_logs_level_idx ON public.plugin_logs USING btree (level);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_logs_plugin_time_idx ON public.plugin_logs USING btree (plugin_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_state_plugin_scope_idx ON public.plugin_state USING btree (plugin_id, scope_kind);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_webhook_deliveries_key_idx ON public.plugin_webhook_deliveries USING btree (webhook_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_webhook_deliveries_plugin_idx ON public.plugin_webhook_deliveries USING btree (plugin_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugin_webhook_deliveries_status_idx ON public.plugin_webhook_deliveries USING btree (status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX plugins_plugin_key_idx ON public.plugins USING btree (plugin_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX plugins_status_idx ON public.plugins USING btree (status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX principal_permission_grants_company_permission_idx ON public.principal_permission_grants USING btree (company_id, permission_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX principal_permission_grants_unique_idx ON public.principal_permission_grants USING btree (company_id, principal_type, principal_id, permission_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_goals_company_idx ON public.project_goals USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_goals_goal_idx ON public.project_goals USING btree (goal_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_goals_project_idx ON public.project_goals USING btree (project_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_workspaces_company_project_idx ON public.project_workspaces USING btree (company_id, project_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_workspaces_company_shared_key_idx ON public.project_workspaces USING btree (company_id, shared_workspace_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_workspaces_project_primary_idx ON public.project_workspaces USING btree (project_id, is_primary);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX project_workspaces_project_remote_ref_idx ON public.project_workspaces USING btree (project_id, remote_provider, remote_workspace_ref);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX project_workspaces_project_source_type_idx ON public.project_workspaces USING btree (project_id, source_type);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX projects_company_idx ON public.projects USING btree (company_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_runs_company_routine_idx ON public.routine_runs USING btree (company_id, routine_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_runs_linked_issue_idx ON public.routine_runs USING btree (linked_issue_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_runs_trigger_idempotency_idx ON public.routine_runs USING btree (trigger_id, idempotency_key);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_runs_trigger_idx ON public.routine_runs USING btree (trigger_id, created_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_triggers_company_kind_idx ON public.routine_triggers USING btree (company_id, kind);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_triggers_company_routine_idx ON public.routine_triggers USING btree (company_id, routine_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_triggers_next_run_idx ON public.routine_triggers USING btree (next_run_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routine_triggers_public_id_idx ON public.routine_triggers USING btree (public_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE UNIQUE INDEX routine_triggers_public_id_uq ON public.routine_triggers USING btree (public_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routines_company_assignee_idx ON public.routines USING btree (company_id, assignee_agent_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routines_company_project_idx ON public.routines USING btree (company_id, project_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX routines_company_status_idx ON public.routines USING btree (company_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_operations_company_run_started_idx ON public.workspace_operations USING btree (company_id, heartbeat_run_id, started_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_operations_company_workspace_started_idx ON public.workspace_operations USING btree (company_id, execution_workspace_id, started_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_runtime_services_company_execution_workspace_status_i ON public.workspace_runtime_services USING btree (company_id, execution_workspace_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_runtime_services_company_project_status_idx ON public.workspace_runtime_services USING btree (company_id, project_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_runtime_services_company_updated_idx ON public.workspace_runtime_services USING btree (company_id, updated_at);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_runtime_services_company_workspace_status_idx ON public.workspace_runtime_services USING btree (company_id, project_workspace_id, status);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
CREATE INDEX workspace_runtime_services_run_idx ON public.workspace_runtime_services USING btree (started_by_run_id);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.activity_log (29 rows)
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d230d4e0-9a58-4e6f-90ca-585cee051f30$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$company.created$paperclip$, $paperclip$company$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, $paperclip${"name":"Foreman"}$paperclip$, $paperclip$2026-04-08T22:06:20.138Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$702c5344-3391-405d-a061-7ff9f0497b48$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip${"name":"CEO","role":"ceo","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T22:07:24.527Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$817d42e1-4b35-4149-8e4e-26d3353639c6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$project.created$paperclip$, $paperclip$project$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip${"name":"Onboarding","workspaceId":null}$paperclip$, $paperclip$2026-04-08T22:07:35.291Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$739eaee9-0438-407b-9b92-e71289f7fec5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, NULL, $paperclip${"title":"Hire your first engineer and create a hiring plan","identifier":"FOR-1"}$paperclip$, $paperclip$2026-04-08T22:07:35.310Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$38dcfafd-b12f-48f5-9cb4-91b18872d97d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.read_marked$paperclip$, $paperclip$issue$paperclip$, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, NULL, $paperclip${"userId":"local-board","lastReadAt":"2026-04-08T22:07:35.636Z"}$paperclip$, $paperclip$2026-04-08T22:07:35.645Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$39e9033d-2288-4c6c-b263-5bdf9fef1cac$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"name":"OpenClawWorker","role":"engineer","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T22:08:35.334Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$fdbb5534-b27e-4812-a43f-d1ff443bfccf$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be$paperclip$, NULL, $paperclip${"title":"P2.1 minimal OpenClaw seam proof","identifier":"FOR-2"}$paperclip$, $paperclip$2026-04-08T22:08:35.341Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d0f2e56d-f2b9-4287-a076-2741418d0fd5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:08:35.351Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c5ef1291-bc1f-4a8a-ad1a-6ce9dd8612b7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:08:56.165Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$01d051e1-6286-49ec-8b25-368fdbea4bdb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:08:56.175Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d8cc81b4-5379-4842-83dd-3c87d1862e0a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:09:17.066Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$98e83548-76eb-4692-b46e-cb95e113b130$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:09:17.073Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$ae8bbaa7-fe28-4b54-8f6c-13eb25b6dfd7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:11:22.184Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1d1da86d-5d6b-45b4-930e-b554d8c3a8c5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities"],"changedAdapterConfigKeys":["command","cwd","graceSec","instructionsBundleMode","instructionsEntryFile","instructionsFilePath","instructionsRootPath","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:12:14.389Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$95a62990-da3e-441a-8af7-ee8991ab513c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T22:12:14.398Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$99c6e3da-220a-4026-b13b-ffebd1870537$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:12:59.819Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$fcf90f8b-3f17-4c00-8e65-462fc7bb06d3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:12:59.829Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c79442b2-66cc-425c-be03-5a025410ce18$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:13:27.945Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4d512566-dd03-42a0-ac99-29b16c618b55$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:14:23.264Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9b109d4d-9e01-45c8-a0ac-fba813767209$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T22:14:39.363Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4072e256-097a-4480-a040-7f2a0bd02b87$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:14:57.279Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$26916765-a804-43ce-84b0-096f759d3df0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:14:57.287Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$325ab74d-3255-402c-b33e-c15ccda0d549$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:15:16.329Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$fea99b53-7b2f-4ee8-81d7-ae522ee030b8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:15:16.336Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$68df8be5-7072-4680-bf6d-f9ef09a68bad$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:15:34.427Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$eddf0c48-f88e-4445-a717-34e900e4b346$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:18:02.814Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$7bf0411d-bc76-428c-9f63-bcdc3cf5f353$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:19:26.743Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$ddcdb1ab-47b6-4b8a-91fd-a34ebb9abf76$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T22:19:26.753Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d1be94a0-1947-47d6-a69a-be1ab71a0dd9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T22:19:42.829Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_config_revisions (10 rows)
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$11f60332-8129-4600-a50d-79f218a41700$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"openclaw agent --session-id paperclip-p21-openclaw -m \"Reply with exactly OPENCLAW_OK and nothing else.\"","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:08:56.163Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$db6ef6f1-40f8-4c79-9958-0a6f5c250116$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:09:17.065Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$1b4b363d-acf5-423e-b729-d8b442687df9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["capabilities","adapterType","adapterConfig"]$paperclip$, $paperclip${"name":"CEO","role":"ceo","title":null,"metadata":null,"reportsTo":null,"adapterType":"cursor","capabilities":null,"adapterConfig":{"model":"auto","graceSec":15,"timeoutSec":0,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"},"runtimeConfig":{"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"CEO","role":"ceo","title":null,"metadata":null,"reportsTo":null,"adapterType":"process","capabilities":"OpenClaw gateway-backed execution (RunPod-backed via Foreman config)","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","graceSec":15,"timeoutSec":240,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"},"runtimeConfig":{"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:12:14.389Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$f6c1fb4e-7bec-4366-bdc9-c4f9f63c60a0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":120},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:12:59.818Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$cbabea8f-af49-4b31-a88b-72a9732412a4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":120},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:13:27.944Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$8ee8ee50-ac74-46c4-8444-b859d77d426d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:14:57.279Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$bf9c080c-8740-4d85-a640-bcbf9759e350$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:15:16.328Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$5cfabae0-01bb-4098-9aca-bbc1d5999a57$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:15:34.426Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$30e494ea-368a-4db9-94e5-81ebafc827dc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:19:26.741Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$3049530d-ffed-4034-b1b0-1f5899db16f4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"OPENCLAW_GATEWAY_URL":{"type":"plain","value":"http://127.0.0.1:9"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T22:19:42.828Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_runtime_state (2 rows)
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T22:07:35.367Z$paperclip$, $paperclip$2026-04-08T22:14:46.838Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$failed$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T22:08:35.351Z$paperclip$, $paperclip$2026-04-08T22:19:42.043Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_wakeup_requests (14 rows)
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$2e706ba7-4f6d-470a-b3ef-8c0240c200ef$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, $paperclip$2026-04-08T22:14:57.283Z$paperclip$, $paperclip$2026-04-08T22:14:57.286Z$paperclip$, $paperclip$2026-04-08T22:15:06.210Z$paperclip$, NULL, $paperclip$2026-04-08T22:14:57.283Z$paperclip$, $paperclip$2026-04-08T22:15:06.210Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$34e19f14-7f5b-4dac-b3eb-40b5c934231e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$assignment$paperclip$, $paperclip$system$paperclip$, $paperclip$issue_assigned$paperclip$, $paperclip${"issueId":"b7119a46-e4d8-4990-8745-ae4af3e76ea8","mutation":"create"}$paperclip$, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$8755c73e-6aa9-416c-bc31-59bd7a7bc12d$paperclip$, $paperclip$2026-04-08T22:07:35.318Z$paperclip$, $paperclip$2026-04-08T22:07:35.334Z$paperclip$, $paperclip$2026-04-08T22:07:35.529Z$paperclip$, $paperclip$Command not found in PATH: "agent"$paperclip$, $paperclip$2026-04-08T22:07:35.318Z$paperclip$, $paperclip$2026-04-08T22:07:35.529Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$ea858066-be90-469d-b75f-45d8d7da68ef$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, $paperclip$2026-04-08T22:09:17.069Z$paperclip$, $paperclip$2026-04-08T22:09:17.072Z$paperclip$, $paperclip$2026-04-08T22:09:37.938Z$paperclip$, NULL, $paperclip$2026-04-08T22:09:17.069Z$paperclip$, $paperclip$2026-04-08T22:09:37.938Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$595476a9-e638-4ebc-b8a7-026774a7dca4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$assignment$paperclip$, $paperclip$system$paperclip$, $paperclip$issue_assigned$paperclip$, $paperclip${"issueId":"edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be","mutation":"create"}$paperclip$, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0$paperclip$, $paperclip$2026-04-08T22:08:35.344Z$paperclip$, $paperclip$2026-04-08T22:08:35.349Z$paperclip$, $paperclip$2026-04-08T22:08:35.379Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, $paperclip$2026-04-08T22:08:35.344Z$paperclip$, $paperclip$2026-04-08T22:08:35.379Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$47a83a7e-08ff-47f4-9674-e65444d0f8a1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, $paperclip$2026-04-08T22:08:35.345Z$paperclip$, $paperclip$2026-04-08T22:08:35.411Z$paperclip$, $paperclip$2026-04-08T22:08:35.446Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, $paperclip$2026-04-08T22:08:35.345Z$paperclip$, $paperclip$2026-04-08T22:08:35.446Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$d52ca3ac-3f8a-44ad-9a75-84b52e104365$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, $paperclip$2026-04-08T22:08:56.169Z$paperclip$, $paperclip$2026-04-08T22:08:56.171Z$paperclip$, $paperclip$2026-04-08T22:08:56.190Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, $paperclip$2026-04-08T22:08:56.169Z$paperclip$, $paperclip$2026-04-08T22:08:56.190Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$d352c40a-322c-47b4-94c8-e668d84877db$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, $paperclip$2026-04-08T22:11:22.179Z$paperclip$, $paperclip$2026-04-08T22:11:22.183Z$paperclip$, $paperclip$2026-04-08T22:11:31.640Z$paperclip$, NULL, $paperclip$2026-04-08T22:11:22.179Z$paperclip$, $paperclip$2026-04-08T22:11:31.640Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$8ea15f90-70d3-41a3-859b-08a3ada480e5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, $paperclip$2026-04-08T22:12:59.824Z$paperclip$, $paperclip$2026-04-08T22:12:59.827Z$paperclip$, $paperclip$2026-04-08T22:13:27.304Z$paperclip$, NULL, $paperclip$2026-04-08T22:12:59.824Z$paperclip$, $paperclip$2026-04-08T22:13:27.304Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$a2066733-2ce3-4457-8bb8-5a4cc50828c9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, $paperclip$2026-04-08T22:12:14.393Z$paperclip$, $paperclip$2026-04-08T22:12:14.397Z$paperclip$, $paperclip$2026-04-08T22:12:41.909Z$paperclip$, NULL, $paperclip$2026-04-08T22:12:14.393Z$paperclip$, $paperclip$2026-04-08T22:12:41.909Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$aa4ceb3a-48f0-49ce-9d03-e2bbb1e2b529$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, $paperclip$2026-04-08T22:14:23.257Z$paperclip$, $paperclip$2026-04-08T22:14:23.262Z$paperclip$, $paperclip$2026-04-08T22:14:37.698Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T22:14:23.257Z$paperclip$, $paperclip$2026-04-08T22:14:37.698Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$4c365f0a-ba4a-4988-bac8-744ae3808a40$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$2026-04-08T22:14:39.354Z$paperclip$, $paperclip$2026-04-08T22:14:39.360Z$paperclip$, $paperclip$2026-04-08T22:14:46.835Z$paperclip$, NULL, $paperclip$2026-04-08T22:14:39.354Z$paperclip$, $paperclip$2026-04-08T22:14:46.835Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$1ce55dc2-25eb-4309-ab8b-7fac581e960a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, $paperclip$2026-04-08T22:15:16.332Z$paperclip$, $paperclip$2026-04-08T22:15:16.335Z$paperclip$, $paperclip$2026-04-08T22:15:33.644Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T22:15:16.332Z$paperclip$, $paperclip$2026-04-08T22:15:33.644Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$ca355930-a461-4cbb-9873-71a5f3c98211$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$2026-04-08T22:19:26.748Z$paperclip$, $paperclip$2026-04-08T22:19:26.752Z$paperclip$, $paperclip$2026-04-08T22:19:42.040Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T22:19:26.748Z$paperclip$, $paperclip$2026-04-08T22:19:42.040Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$305eb2f0-e7e3-47ac-9b26-e555fad5811e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, $paperclip$2026-04-08T22:18:02.790Z$paperclip$, $paperclip$2026-04-08T22:18:02.806Z$paperclip$, $paperclip$2026-04-08T22:19:10.365Z$paperclip$, NULL, $paperclip$2026-04-08T22:18:02.790Z$paperclip$, $paperclip$2026-04-08T22:19:10.366Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agents (2 rows)
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$CEO$paperclip$, $paperclip$ceo$paperclip$, NULL, $paperclip$idle$paperclip$, NULL, $paperclip$OpenClaw gateway-backed execution (RunPod-backed via Foreman config)$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","graceSec":15,"timeoutSec":240,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"}$paperclip$, 0, 0, $paperclip$2026-04-08T22:14:46.839Z$paperclip$, NULL, $paperclip$2026-04-08T22:07:24.514Z$paperclip$, $paperclip$2026-04-08T22:14:46.839Z$paperclip$, $paperclip${"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}}$paperclip$, $paperclip${"canCreateAgents":true}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$OpenClawWorker$paperclip$, $paperclip$engineer$paperclip$, $paperclip$OpenClaw Runtime Worker$paperclip$, $paperclip$error$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$OpenClaw gateway-backed execution$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-08T22:19:42.044Z$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.333Z$paperclip$, $paperclip$2026-04-08T22:19:42.826Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.companies (1 rows)
INSERT INTO "public"."companies" ("id", "name", "description", "status", "budget_monthly_cents", "spent_monthly_cents", "created_at", "updated_at", "issue_prefix", "issue_counter", "require_board_approval_for_new_agents", "brand_color", "pause_reason", "paused_at", "feedback_data_sharing_enabled", "feedback_data_sharing_consent_at", "feedback_data_sharing_consent_by_user_id", "feedback_data_sharing_terms_version") VALUES ($paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$Foreman$paperclip$, NULL, $paperclip$active$paperclip$, 0, 0, $paperclip$2026-04-08T22:06:20.123Z$paperclip$, $paperclip$2026-04-08T22:06:20.123Z$paperclip$, $paperclip$FOR$paperclip$, 2, true, NULL, NULL, NULL, false, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.company_memberships (3 rows)
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$db303805-43c5-4486-ab3d-2a36d8f8e08c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$active$paperclip$, $paperclip$owner$paperclip$, $paperclip$2026-04-08T22:06:20.133Z$paperclip$, $paperclip$2026-04-08T22:06:20.133Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$a3c3d76e-db00-4ddf-be65-049ebc224664$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T22:07:24.529Z$paperclip$, $paperclip$2026-04-08T22:07:24.529Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$6d2f77a5-b369-4738-94c0-b77f31345487$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T22:08:35.335Z$paperclip$, $paperclip$2026-04-08T22:08:35.335Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.company_skills (4 rows)
INSERT INTO "public"."company_skills" ("id", "company_id", "key", "slug", "name", "description", "markdown", "source_type", "source_locator", "source_ref", "trust_level", "compatibility", "file_inventory", "metadata", "created_at", "updated_at") VALUES ($paperclip$4df8a129-a731-46c0-9776-9fd654db20b1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$paperclipai/paperclip/paperclip-create-agent$paperclip$, $paperclip$paperclip-create-agent$paperclip$, $paperclip$paperclip-create-agent$paperclip$, $paperclip$>$paperclip$, $paperclip$---
name: paperclip-create-agent
description: >
  Create new agents in Paperclip with governance-aware hiring. Use when you need
  to inspect adapter configuration options, compare existing agent configs,
  draft a new agent prompt/config, and submit a hire request.
---

# Paperclip Create Agent Skill

Use this skill when you are asked to hire/create an agent.

## Preconditions

You need either:

- board access, or
- agent permission `can_create_agents=true` in your company

If you do not have this permission, escalate to your CEO or board.

## Workflow

1. Confirm identity and company context.

```sh
curl -sS "$PAPERCLIP_API_URL/api/agents/me" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

2. Discover available adapter configuration docs for this Paperclip instance.

```sh
curl -sS "$PAPERCLIP_API_URL/llms/agent-configuration.txt" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

3. Read adapter-specific docs (example: `claude_local`).

```sh
curl -sS "$PAPERCLIP_API_URL/llms/agent-configuration/claude_local.txt" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

4. Compare existing agent configurations in your company.

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/agent-configurations" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

5. Discover allowed agent icons and pick one that matches the role.

```sh
curl -sS "$PAPERCLIP_API_URL/llms/agent-icons.txt" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

6. Draft the new hire config:
- role/title/name
- icon (required in practice; use one from `/llms/agent-icons.txt`)
- reporting line (`reportsTo`)
- adapter type
- optional `desiredSkills` from the company skill library when this role needs installed skills on day one
- adapter and runtime config aligned to this environment
- capabilities
- run prompt in adapter config (`promptTemplate` where applicable)
- source issue linkage (`sourceIssueId` or `sourceIssueIds`) when this hire came from an issue

7. Submit hire request.

```sh
curl -sS -X POST "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/agent-hires" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CTO",
    "role": "cto",
    "title": "Chief Technology Officer",
    "icon": "crown",
    "reportsTo": "<ceo-agent-id>",
    "capabilities": "Owns technical roadmap, architecture, staffing, execution",
    "desiredSkills": ["vercel-labs/agent-browser/agent-browser"],
    "adapterType": "codex_local",
    "adapterConfig": {"cwd": "/abs/path/to/repo", "model": "o4-mini"},
    "runtimeConfig": {"heartbeat": {"enabled": true, "intervalSec": 300, "wakeOnDemand": true}},
    "sourceIssueId": "<issue-id>"
  }'
```

8. Handle governance state:
- if response has `approval`, hire is `pending_approval`
- monitor and discuss on approval thread
- when the board approves, you will be woken with `PAPERCLIP_APPROVAL_ID`; read linked issues and close/comment follow-up

```sh
curl -sS "$PAPERCLIP_API_URL/api/approvals/<approval-id>" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"

curl -sS -X POST "$PAPERCLIP_API_URL/api/approvals/<approval-id>/comments" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"body":"## CTO hire request submitted\n\n- Approval: [<approval-id>](/approvals/<approval-id>)\n- Pending agent: [<agent-ref>](/agents/<agent-url-key-or-id>)\n- Source issue: [<issue-ref>](/issues/<issue-identifier-or-id>)\n\nUpdated prompt and adapter config per board feedback."}'
```

If the approval already exists and needs manual linking to the issue:

```sh
curl -sS -X POST "$PAPERCLIP_API_URL/api/issues/<issue-id>/approvals" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"approvalId":"<approval-id>"}'
```

After approval is granted, run this follow-up loop:

```sh
curl -sS "$PAPERCLIP_API_URL/api/approvals/$PAPERCLIP_APPROVAL_ID" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"

curl -sS "$PAPERCLIP_API_URL/api/approvals/$PAPERCLIP_APPROVAL_ID/issues" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

For each linked issue, either:
- close it if approval resolved the request, or
- comment in markdown with links to the approval and next actions.

## Quality Bar

Before sending a hire request:

- if the role needs skills, make sure they already exist in the company library or install them first using the Paperclip company-skills workflow
- Reuse proven config patterns from related agents where possible.
- Set a concrete `icon` from `/llms/agent-icons.txt` so the new hire is identifiable in org and task views.
- Avoid secrets in plain text unless required by adapter behavior.
- Ensure reporting line is correct and in-company.
- Ensure prompt is role-specific and operationally scoped.
- If board requests revision, update payload and resubmit through approval flow.

For endpoint payload shapes and full examples, read:
`skills/paperclip-create-agent/references/api-reference.md`
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip-create-agent$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/api-reference.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip-create-agent","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.391Z$paperclip$, $paperclip$2026-04-08T22:19:26.759Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_skills" ("id", "company_id", "key", "slug", "name", "description", "markdown", "source_type", "source_locator", "source_ref", "trust_level", "compatibility", "file_inventory", "metadata", "created_at", "updated_at") VALUES ($paperclip$099fd1c9-787f-42f1-8d95-db8b91d32e32$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$paperclipai/paperclip/paperclip-create-plugin$paperclip$, $paperclip$paperclip-create-plugin$paperclip$, $paperclip$paperclip-create-plugin$paperclip$, $paperclip$>$paperclip$, $paperclip$---
name: paperclip-create-plugin
description: >
  Create new Paperclip plugins with the current alpha SDK/runtime. Use when
  scaffolding a plugin package, adding a new example plugin, or updating plugin
  authoring docs. Covers the supported worker/UI surface, route conventions,
  scaffold flow, and verification steps.
---

# Create a Paperclip Plugin

Use this skill when the task is to create, scaffold, or document a Paperclip plugin.

## 1. Ground rules

Read these first when needed:

1. `doc/plugins/PLUGIN_AUTHORING_GUIDE.md`
2. `packages/plugins/sdk/README.md`
3. `doc/plugins/PLUGIN_SPEC.md` only for future-looking context

Current runtime assumptions:

- plugin workers are trusted code
- plugin UI is trusted same-origin host code
- worker APIs are capability-gated
- plugin UI is not sandboxed by manifest capabilities
- no host-provided shared plugin UI component kit yet
- `ctx.assets` is not supported in the current runtime

## 2. Preferred workflow

Use the scaffold package instead of hand-writing the boilerplate:

```bash
pnpm --filter @paperclipai/create-paperclip-plugin build
node packages/plugins/create-paperclip-plugin/dist/index.js <npm-package-name> --output <target-dir>
```

For a plugin that lives outside the Paperclip repo, pass `--sdk-path` and let the scaffold snapshot the local SDK/shared packages into `.paperclip-sdk/`:

```bash
pnpm --filter @paperclipai/create-paperclip-plugin build
node packages/plugins/create-paperclip-plugin/dist/index.js @acme/plugin-name \
  --output /absolute/path/to/plugin-repos \
  --sdk-path /absolute/path/to/paperclip/packages/plugins/sdk
```

Recommended target inside this repo:

- `packages/plugins/examples/` for example plugins
- another `packages/plugins/<name>/` folder if it is becoming a real package

## 3. After scaffolding

Check and adjust:

- `src/manifest.ts`
- `src/worker.ts`
- `src/ui/index.tsx`
- `tests/plugin.spec.ts`
- `package.json`

Make sure the plugin:

- declares only supported capabilities
- does not use `ctx.assets`
- does not import host UI component stubs
- keeps UI self-contained
- uses `routePath` only on `page` slots
- is installed into Paperclip from an absolute local path during development

## 4. If the plugin should appear in the app

For bundled example/discoverable behavior, update the relevant host wiring:

- bundled example list in `server/src/routes/plugins.ts`
- any docs that list in-repo examples

Only do this if the user wants the plugin surfaced as a bundled example.

## 5. Verification

Always run:

```bash
pnpm --filter <plugin-package> typecheck
pnpm --filter <plugin-package> test
pnpm --filter <plugin-package> build
```

If you changed SDK/host/plugin runtime code too, also run broader repo checks as appropriate.

## 6. Documentation expectations

When authoring or updating plugin docs:

- distinguish current implementation from future spec ideas
- be explicit about the trusted-code model
- do not promise host UI components or asset APIs
- prefer npm-package deployment guidance over repo-local workflows for production
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip-create-plugin$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip-create-plugin","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.408Z$paperclip$, $paperclip$2026-04-08T22:19:26.761Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_skills" ("id", "company_id", "key", "slug", "name", "description", "markdown", "source_type", "source_locator", "source_ref", "trust_level", "compatibility", "file_inventory", "metadata", "created_at", "updated_at") VALUES ($paperclip$fd239600-41ed-4bd2-a3c0-10b9c7faff53$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$paperclipai/paperclip/para-memory-files$paperclip$, $paperclip$para-memory-files$paperclip$, $paperclip$para-memory-files$paperclip$, $paperclip$>$paperclip$, $paperclip$---
name: para-memory-files
description: >
  File-based memory system using Tiago Forte's PARA method. Use this skill whenever
  you need to store, retrieve, update, or organize knowledge across sessions. Covers
  three memory layers: (1) Knowledge graph in PARA folders with atomic YAML facts,
  (2) Daily notes as raw timeline, (3) Tacit knowledge about user patterns. Also
  handles planning files, memory decay, weekly synthesis, and recall via qmd.
  Trigger on any memory operation: saving facts, writing daily notes, creating
  entities, running weekly synthesis, recalling past context, or managing plans.
---

# PARA Memory Files

Persistent, file-based memory organized by Tiago Forte's PARA method. Three layers: a knowledge graph, daily notes, and tacit knowledge. All paths are relative to `$AGENT_HOME`.

## Three Memory Layers

### Layer 1: Knowledge Graph (`$AGENT_HOME/life/` -- PARA)

Entity-based storage. Each entity gets a folder with two tiers:

1. `summary.md` -- quick context, load first.
2. `items.yaml` -- atomic facts, load on demand.

```text
$AGENT_HOME/life/
  projects/          # Active work with clear goals/deadlines
    <name>/
      summary.md
      items.yaml
  areas/             # Ongoing responsibilities, no end date
    people/<name>/
    companies/<name>/
  resources/         # Reference material, topics of interest
    <topic>/
  archives/          # Inactive items from the other three
  index.md
```

**PARA rules:**

- **Projects** -- active work with a goal or deadline. Move to archives when complete.
- **Areas** -- ongoing (people, companies, responsibilities). No end date.
- **Resources** -- reference material, topics of interest.
- **Archives** -- inactive items from any category.

**Fact rules:**

- Save durable facts immediately to `items.yaml`.
- Weekly: rewrite `summary.md` from active facts.
- Never delete facts. Supersede instead (`status: superseded`, add `superseded_by`).
- When an entity goes inactive, move its folder to `$AGENT_HOME/life/archives/`.

**When to create an entity:**

- Mentioned 3+ times, OR
- Direct relationship to the user (family, coworker, partner, client), OR
- Significant project or company in the user's life.
- Otherwise, note it in daily notes.

For the atomic fact YAML schema and memory decay rules, see [references/schemas.md](references/schemas.md).

### Layer 2: Daily Notes (`$AGENT_HOME/memory/YYYY-MM-DD.md`)

Raw timeline of events -- the "when" layer.

- Write continuously during conversations.
- Extract durable facts to Layer 1 during heartbeats.

### Layer 3: Tacit Knowledge (`$AGENT_HOME/MEMORY.md`)

How the user operates -- patterns, preferences, lessons learned.

- Not facts about the world; facts about the user.
- Update whenever you learn new operating patterns.

## Write It Down -- No Mental Notes

Memory does not survive session restarts. Files do.

- Want to remember something -> WRITE IT TO A FILE.
- "Remember this" -> update `$AGENT_HOME/memory/YYYY-MM-DD.md` or the relevant entity file.
- Learn a lesson -> update AGENTS.md, TOOLS.md, or the relevant skill file.
- Make a mistake -> document it so future-you does not repeat it.
- On-disk text files are always better than holding it in temporary context.

## Memory Recall -- Use qmd

Use `qmd` rather than grepping files:

```bash
qmd query "what happened at Christmas"   # Semantic search with reranking
qmd search "specific phrase"              # BM25 keyword search
qmd vsearch "conceptual question"         # Pure vector similarity
```

Index your personal folder: `qmd index $AGENT_HOME`

Vectors + BM25 + reranking finds things even when the wording differs.

## Planning

Keep plans in timestamped files in `plans/` at the project root (outside personal memory so other agents can access them). Use `qmd` to search plans. Plans go stale -- if a newer plan exists, do not confuse yourself with an older version. If you notice staleness, update the file to note what it is supersededBy.
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/para-memory-files$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/schemas.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/para-memory-files","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.417Z$paperclip$, $paperclip$2026-04-08T22:19:26.762Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_skills" ("id", "company_id", "key", "slug", "name", "description", "markdown", "source_type", "source_locator", "source_ref", "trust_level", "compatibility", "file_inventory", "metadata", "created_at", "updated_at") VALUES ($paperclip$0108e3c4-c621-41d5-b57b-ff694e15fab2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$paperclipai/paperclip/paperclip$paperclip$, $paperclip$paperclip$paperclip$, $paperclip$paperclip$paperclip$, $paperclip$>$paperclip$, $paperclip$---
name: paperclip
description: >
  Interact with the Paperclip control plane API to manage tasks, coordinate with
  other agents, and follow company governance. Use when you need to check
  assignments, update task status, delegate work, post comments, set up or manage
  routines (recurring scheduled tasks), or call any Paperclip API endpoint. Do NOT
  use for the actual domain work itself (writing code, research, etc.) — only for
  Paperclip coordination.
---

# Paperclip Skill

You run in **heartbeats** — short execution windows triggered by Paperclip. Each heartbeat, you wake up, check your work, do something useful, and exit. You do not run continuously.

## Authentication

Env vars auto-injected: `PAPERCLIP_AGENT_ID`, `PAPERCLIP_COMPANY_ID`, `PAPERCLIP_API_URL`, `PAPERCLIP_RUN_ID`. Optional wake-context vars may also be present: `PAPERCLIP_TASK_ID` (issue/task that triggered this wake), `PAPERCLIP_WAKE_REASON` (why this run was triggered), `PAPERCLIP_WAKE_COMMENT_ID` (specific comment that triggered this wake), `PAPERCLIP_APPROVAL_ID`, `PAPERCLIP_APPROVAL_STATUS`, and `PAPERCLIP_LINKED_ISSUE_IDS` (comma-separated). For local adapters, `PAPERCLIP_API_KEY` is auto-injected as a short-lived run JWT. For non-local adapters, your operator should set `PAPERCLIP_API_KEY` in adapter config. All requests use `Authorization: Bearer $PAPERCLIP_API_KEY`. All endpoints under `/api`, all JSON. Never hard-code the API URL.

Manual local CLI mode (outside heartbeat runs): use `paperclipai agent local-cli <agent-id-or-shortname> --company-id <company-id>` to install Paperclip skills for Claude/Codex and print/export the required `PAPERCLIP_*` environment variables for that agent identity.

**Run audit trail:** You MUST include `-H 'X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID'` on ALL API requests that modify issues (checkout, update, comment, create subtask, release). This links your actions to the current heartbeat run for traceability.

## The Heartbeat Procedure

Follow these steps every time you wake up:

**Step 1 — Identity.** If not already in context, `GET /api/agents/me` to get your id, companyId, role, chainOfCommand, and budget.

**Step 2 — Approval follow-up (when triggered).** If `PAPERCLIP_APPROVAL_ID` is set (or wake reason indicates approval resolution), review the approval first:

- `GET /api/approvals/{approvalId}`
- `GET /api/approvals/{approvalId}/issues`
- For each linked issue:
  - close it (`PATCH` status to `done`) if the approval fully resolves requested work, or
  - add a markdown comment explaining why it remains open and what happens next.
    Always include links to the approval and issue in that comment.

**Step 3 — Get assignments.** Prefer `GET /api/agents/me/inbox-lite` for the normal heartbeat inbox. It returns the compact assignment list you need for prioritization. Fall back to `GET /api/companies/{companyId}/issues?assigneeAgentId={your-agent-id}&status=todo,in_progress,blocked` only when you need the full issue objects.

**Step 4 — Pick work (with mention exception).** Work on `in_progress` first, then `todo`. Skip `blocked` unless you can unblock it.
**Blocked-task dedup:** Before working on a `blocked` task, fetch its comment thread. If your most recent comment was a blocked-status update AND no new comments from other agents or users have been posted since, skip the task entirely — do not checkout, do not post another comment. Exit the heartbeat (or move to the next task) instead. Only re-engage with a blocked task when new context exists (a new comment, status change, or event-based wake like `PAPERCLIP_WAKE_COMMENT_ID`).
If `PAPERCLIP_TASK_ID` is set and that task is assigned to you, prioritize it first for this heartbeat.
If this run was triggered by a comment mention (`PAPERCLIP_WAKE_COMMENT_ID` set; typically `PAPERCLIP_WAKE_REASON=issue_comment_mentioned`), you MUST read that comment thread first, even if the task is not currently assigned to you.
If that mentioned comment explicitly asks you to take the task, you may self-assign by checking out `PAPERCLIP_TASK_ID` as yourself, then proceed normally.
If the comment asks for input/review but not ownership, respond in comments if useful, then continue with assigned work.
If the comment does not direct you to take ownership, do not self-assign.
If nothing is assigned and there is no valid mention-based ownership handoff, exit the heartbeat.

**Step 5 — Checkout.** You MUST checkout before doing any work. Include the run ID header:

```
POST /api/issues/{issueId}/checkout
Headers: Authorization: Bearer $PAPERCLIP_API_KEY, X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID
{ "agentId": "{your-agent-id}", "expectedStatuses": ["todo", "backlog", "blocked"] }
```

If already checked out by you, returns normally. If owned by another agent: `409 Conflict` — stop, pick a different task. **Never retry a 409.**

**Step 6 — Understand context.** Prefer `GET /api/issues/{issueId}/heartbeat-context` first. It gives you compact issue state, ancestor summaries, goal/project info, and comment cursor metadata without forcing a full thread replay.

Use comments incrementally:

- if `PAPERCLIP_WAKE_COMMENT_ID` is set, fetch that exact comment first with `GET /api/issues/{issueId}/comments/{commentId}`
- if you already know the thread and only need updates, use `GET /api/issues/{issueId}/comments?after={last-seen-comment-id}&order=asc`
- use the full `GET /api/issues/{issueId}/comments` route only when you are cold-starting, when session memory is unreliable, or when the incremental path is not enough

Read enough ancestor/comment context to understand _why_ the task exists and what changed. Do not reflexively reload the whole thread on every heartbeat.

**Step 7 — Do the work.** Use your tools and capabilities.

**Step 8 — Update status and communicate.** Always include the run ID header.
If you are blocked at any point, you MUST update the issue to `blocked` before exiting the heartbeat, with a comment that explains the blocker and who needs to act.

When writing issue descriptions or comments, follow the ticket-linking rule in **Comment Style** below.

```json
PATCH /api/issues/{issueId}
Headers: X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID
{ "status": "done", "comment": "What was done and why." }

PATCH /api/issues/{issueId}
Headers: X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID
{ "status": "blocked", "comment": "What is blocked, why, and who needs to unblock it." }
```

Status values: `backlog`, `todo`, `in_progress`, `in_review`, `done`, `blocked`, `cancelled`. Priority values: `critical`, `high`, `medium`, `low`. Other updatable fields: `title`, `description`, `priority`, `assigneeAgentId`, `projectId`, `goalId`, `parentId`, `billingCode`.

**Step 9 — Delegate if needed.** Create subtasks with `POST /api/companies/{companyId}/issues`. Always set `parentId` and `goalId`. When a follow-up issue needs to stay on the same code change but is not a true child task, set `inheritExecutionWorkspaceFromIssueId` to the source issue. Set `billingCode` for cross-team work.

## Project Setup Workflow (CEO/Manager Common Path)

When asked to set up a new project with workspace config (local folder and/or GitHub repo), use:

1. `POST /api/companies/{companyId}/projects` with project fields.
2. Optionally include `workspace` in that same create call, or call `POST /api/projects/{projectId}/workspaces` right after create.

Workspace rules:

- Provide at least one of `cwd` (local folder) or `repoUrl` (remote repo).
- For repo-only setup, omit `cwd` and provide `repoUrl`.
- Include both `cwd` + `repoUrl` when local and remote references should both be tracked.

## OpenClaw Invite Workflow (CEO)

Use this when asked to invite a new OpenClaw employee.

1. Generate a fresh OpenClaw invite prompt:

```
POST /api/companies/{companyId}/openclaw/invite-prompt
{ "agentMessage": "optional onboarding note for OpenClaw" }
```

Access control:

- Board users with invite permission can call it.
- Agent callers: only the company CEO agent can call it.

2. Build the copy-ready OpenClaw prompt for the board:

- Use `onboardingTextUrl` from the response.
- Ask the board to paste that prompt into OpenClaw.
- If the issue includes an OpenClaw URL (for example `ws://127.0.0.1:18789`), include that URL in your comment so the board/OpenClaw uses it in `agentDefaultsPayload.url`.

3. Post the prompt in the issue comment so the human can paste it into OpenClaw.

4. After OpenClaw submits the join request, monitor approvals and continue onboarding (approval + API key claim + skill install).

## Company Skills Workflow

Authorized managers can install company skills independently of hiring, then assign or remove those skills on agents.

- Install and inspect company skills with the company skills API.
- Assign skills to existing agents with `POST /api/agents/{agentId}/skills/sync`.
- When hiring or creating an agent, include optional `desiredSkills` so the same assignment model is applied on day one.

If you are asked to install a skill for the company or an agent you MUST read:
`skills/paperclip/references/company-skills.md`

## Routines

Routines are recurring tasks. Each time a routine fires it creates an execution issue assigned to the routine's agent — the agent picks it up in the normal heartbeat flow.

- Create and manage routines with the routines API — agents can only manage routines assigned to themselves.
- Add triggers per routine: `schedule` (cron), `webhook`, or `api` (manual).
- Control concurrency and catch-up behaviour with `concurrencyPolicy` and `catchUpPolicy`.

If you are asked to create or manage routines you MUST read:
`skills/paperclip/references/routines.md`

## Critical Rules

- **Always checkout** before working. Never PATCH to `in_progress` manually.
- **Never retry a 409.** The task belongs to someone else.
- **Never look for unassigned work.**
- **Self-assign only for explicit @-mention handoff.** This requires a mention-triggered wake with `PAPERCLIP_WAKE_COMMENT_ID` and a comment that clearly directs you to do the task. Use checkout (never direct assignee patch). Otherwise, no assignments = exit.
- **Honor "send it back to me" requests from board users.** If a board/user asks for review handoff (e.g. "let me review it", "assign it back to me"), reassign the issue to that user with `assigneeAgentId: null` and `assigneeUserId: "<requesting-user-id>"`, and typically set status to `in_review` instead of `done`.
  Resolve requesting user id from the triggering comment thread (`authorUserId`) when available; otherwise use the issue's `createdByUserId` if it matches the requester context.
- **Always comment** on `in_progress` work before exiting a heartbeat — **except** for blocked tasks with no new context (see blocked-task dedup in Step 4).
- **Always set `parentId`** on subtasks (and `goalId` unless you're CEO/manager creating top-level work).
- **Preserve workspace continuity for follow-ups.** Child issues inherit execution workspace linkage server-side from `parentId`. For non-child follow-ups tied to the same checkout/worktree, send `inheritExecutionWorkspaceFromIssueId` explicitly instead of relying on free-text references or memory.
- **Never cancel cross-team tasks.** Reassign to your manager with a comment.
- **Always update blocked issues explicitly.** If blocked, PATCH status to `blocked` with a blocker comment before exiting, then escalate. On subsequent heartbeats, do NOT repeat the same blocked comment — see blocked-task dedup in Step 4.
- **@-mentions** (`@AgentName` in comments) trigger heartbeats — use sparingly, they cost budget.
- **Budget**: auto-paused at 100%. Above 80%, focus on critical tasks only.
- **Escalate** via `chainOfCommand` when stuck. Reassign to manager or create a task for them.
- **Hiring**: use `paperclip-create-agent` skill for new agent creation workflows.
- **Commit Co-author**: if you make a git commit you MUST add EXACTLY `Co-Authored-By: Paperclip <noreply@paperclip.ing>` to the end of each commit message. Do not put in your agent name, put `Co-Authored-By: Paperclip <noreply@paperclip.ing>`

## Comment Style (Required)

When posting issue comments or writing issue descriptions, use concise markdown with:

- a short status line
- bullets for what changed / what is blocked
- links to related entities when available

**Ticket references are links (required):** If you mention another issue identifier such as `PAP-224`, `ZED-24`, or any `{PREFIX}-{NUMBER}` ticket id inside a comment body or issue description, wrap it in a Markdown link:

- `[PAP-224](/PAP/issues/PAP-224)`
- `[ZED-24](/ZED/issues/ZED-24)`

Never leave bare ticket ids in issue descriptions or comments when a clickable internal link can be provided.

**Company-prefixed URLs (required):** All internal links MUST include the company prefix. Derive the prefix from any issue identifier you have (e.g., `PAP-315` → prefix is `PAP`). Use this prefix in all UI links:

- Issues: `/<prefix>/issues/<issue-identifier>` (e.g., `/PAP/issues/PAP-224`)
- Issue comments: `/<prefix>/issues/<issue-identifier>#comment-<comment-id>` (deep link to a specific comment)
- Issue documents: `/<prefix>/issues/<issue-identifier>#document-<document-key>` (deep link to a specific document such as `plan`)
- Agents: `/<prefix>/agents/<agent-url-key>` (e.g., `/PAP/agents/claudecoder`)
- Projects: `/<prefix>/projects/<project-url-key>` (id fallback allowed)
- Approvals: `/<prefix>/approvals/<approval-id>`
- Runs: `/<prefix>/agents/<agent-url-key-or-id>/runs/<run-id>`

Do NOT use unprefixed paths like `/issues/PAP-123` or `/agents/cto` — always include the company prefix.

Example:

```md
## Update

Submitted CTO hire request and linked it for board review.

- Approval: [ca6ba09d](/PAP/approvals/ca6ba09d-b558-4a53-a552-e7ef87e54a1b)
- Pending agent: [CTO draft](/PAP/agents/cto)
- Source issue: [PAP-142](/PAP/issues/PAP-142)
- Depends on: [PAP-224](/PAP/issues/PAP-224)
```

## Planning (Required when planning requested)

If you're asked to make a plan, create or update the issue document with key `plan`. Do not append plans into the issue description anymore. If you're asked for plan revisions, update that same `plan` document. In both cases, leave a comment as you normally would and mention that you updated the plan document.

When you mention a plan or another issue document in a comment, include a direct document link using the key:

- Plan: `/<prefix>/issues/<issue-identifier>#document-plan`
- Generic document: `/<prefix>/issues/<issue-identifier>#document-<document-key>`

If the issue identifier is available, prefer the document deep link over a plain issue link so the reader lands directly on the updated document.

If you're asked to make a plan, _do not mark the issue as done_. Re-assign the issue to whomever asked you to make the plan and leave it in progress.

Recommended API flow:

```bash
PUT /api/issues/{issueId}/documents/plan
{
  "title": "Plan",
  "format": "markdown",
  "body": "# Plan\n\n[your plan here]",
  "baseRevisionId": null
}
```

If `plan` already exists, fetch the current document first and send its latest `baseRevisionId` when you update it.

## Setting Agent Instructions Path

Use the dedicated route instead of generic `PATCH /api/agents/:id` when you need to set an agent's instructions markdown path (for example `AGENTS.md`).

```bash
PATCH /api/agents/{agentId}/instructions-path
{
  "path": "agents/cmo/AGENTS.md"
}
```

Rules:

- Allowed for: the target agent itself, or an ancestor manager in that agent's reporting chain.
- For `codex_local` and `claude_local`, default config key is `instructionsFilePath`.
- Relative paths are resolved against the target agent's `adapterConfig.cwd`; absolute paths are accepted as-is.
- To clear the path, send `{ "path": null }`.
- For adapters with a different key, provide it explicitly:

```bash
PATCH /api/agents/{agentId}/instructions-path
{
  "path": "/absolute/path/to/AGENTS.md",
  "adapterConfigKey": "yourAdapterSpecificPathField"
}
```

## Key Endpoints (Quick Reference)

| Action                                    | Endpoint                                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------------------------ |
| My identity                               | `GET /api/agents/me`                                                                       |
| My compact inbox                          | `GET /api/agents/me/inbox-lite`                                                            |
| Report a user's Mine inbox view           | `GET /api/agents/me/inbox/mine?userId=:userId`                                             |
| My assignments                            | `GET /api/companies/:companyId/issues?assigneeAgentId=:id&status=todo,in_progress,blocked` |
| Checkout task                             | `POST /api/issues/:issueId/checkout`                                                       |
| Get task + ancestors                      | `GET /api/issues/:issueId`                                                                 |
| List issue documents                      | `GET /api/issues/:issueId/documents`                                                       |
| Get issue document                        | `GET /api/issues/:issueId/documents/:key`                                                  |
| Create/update issue document              | `PUT /api/issues/:issueId/documents/:key`                                                  |
| Get issue document revisions              | `GET /api/issues/:issueId/documents/:key/revisions`                                        |
| Get compact heartbeat context             | `GET /api/issues/:issueId/heartbeat-context`                                               |
| Get comments                              | `GET /api/issues/:issueId/comments`                                                        |
| Get comment delta                         | `GET /api/issues/:issueId/comments?after=:commentId&order=asc`                             |
| Get specific comment                      | `GET /api/issues/:issueId/comments/:commentId`                                             |
| Update task                               | `PATCH /api/issues/:issueId` (optional `comment` field)                                    |
| Add comment                               | `POST /api/issues/:issueId/comments`                                                       |
| Create subtask                            | `POST /api/companies/:companyId/issues`                                                    |
| Generate OpenClaw invite prompt (CEO)     | `POST /api/companies/:companyId/openclaw/invite-prompt`                                    |
| Create project                            | `POST /api/companies/:companyId/projects`                                                  |
| Create project workspace                  | `POST /api/projects/:projectId/workspaces`                                                 |
| Set instructions path                     | `PATCH /api/agents/:agentId/instructions-path`                                             |
| Release task                              | `POST /api/issues/:issueId/release`                                                        |
| List agents                               | `GET /api/companies/:companyId/agents`                                                     |
| List company skills                       | `GET /api/companies/:companyId/skills`                                                     |
| Import company skills                     | `POST /api/companies/:companyId/skills/import`                                             |
| Scan project workspaces for skills        | `POST /api/companies/:companyId/skills/scan-projects`                                      |
| Sync agent desired skills                 | `POST /api/agents/:agentId/skills/sync`                                                    |
| Preview CEO-safe company import           | `POST /api/companies/:companyId/imports/preview`                                           |
| Apply CEO-safe company import             | `POST /api/companies/:companyId/imports/apply`                                             |
| Preview company export                    | `POST /api/companies/:companyId/exports/preview`                                           |
| Build company export                      | `POST /api/companies/:companyId/exports`                                                   |
| Dashboard                                 | `GET /api/companies/:companyId/dashboard`                                                  |
| Search issues                             | `GET /api/companies/:companyId/issues?q=search+term`                                       |
| Upload attachment (multipart, field=file) | `POST /api/companies/:companyId/issues/:issueId/attachments`                               |
| List issue attachments                    | `GET /api/issues/:issueId/attachments`                                                     |
| Get attachment content                    | `GET /api/attachments/:attachmentId/content`                                               |
| Delete attachment                         | `DELETE /api/attachments/:attachmentId`                                                    |
| List routines                             | `GET /api/companies/:companyId/routines`                                                   |
| Get routine                               | `GET /api/routines/:routineId`                                                             |
| Create routine                            | `POST /api/companies/:companyId/routines`                                                  |
| Update routine                            | `PATCH /api/routines/:routineId`                                                           |
| Add trigger                               | `POST /api/routines/:routineId/triggers`                                                   |
| Update trigger                            | `PATCH /api/routine-triggers/:triggerId`                                                   |
| Delete trigger                            | `DELETE /api/routine-triggers/:triggerId`                                                  |
| Rotate webhook secret                     | `POST /api/routine-triggers/:triggerId/rotate-secret`                                      |
| Manual run                                | `POST /api/routines/:routineId/run`                                                        |
| Fire webhook (external)                   | `POST /api/routine-triggers/public/:publicId/fire`                                         |
| List runs                                 | `GET /api/routines/:routineId/runs`                                                        |

## Company Import / Export

Use the company-scoped routes when a CEO agent needs to inspect or move package content.

- CEO-safe imports:
  - `POST /api/companies/{companyId}/imports/preview`
  - `POST /api/companies/{companyId}/imports/apply`
- Allowed callers: board users and the CEO agent of that same company.
- Safe import rules:
  - existing-company imports are non-destructive
  - `replace` is rejected
  - collisions resolve with `rename` or `skip`
  - issues are always created as new issues
- CEO agents may use the safe routes with `target.mode = "new_company"` to create a new company directly. Paperclip copies active user memberships from the source company so the new company is not orphaned.

For export, preview first and keep tasks explicit:

- `POST /api/companies/{companyId}/exports/preview`
- `POST /api/companies/{companyId}/exports`
- Export preview defaults to `issues: false`
- Add `issues` or `projectIssues` only when you intentionally need task files
- Use `selectedFiles` to narrow the final package to specific agents, skills, projects, or tasks after you inspect the preview inventory

## Searching Issues

Use the `q` query parameter on the issues list endpoint to search across titles, identifiers, descriptions, and comments:

```
GET /api/companies/{companyId}/issues?q=dockerfile
```

Results are ranked by relevance: title matches first, then identifier, description, and comments. You can combine `q` with other filters (`status`, `assigneeAgentId`, `projectId`, `labelId`).

## Self-Test Playbook (App-Level)

Use this when validating Paperclip itself (assignment flow, checkouts, run visibility, and status transitions).

1. Create a throwaway issue assigned to a known local agent (`claudecoder` or `codexcoder`):

```bash
npx paperclipai issue create \
  --company-id "$PAPERCLIP_COMPANY_ID" \
  --title "Self-test: assignment/watch flow" \
  --description "Temporary validation issue" \
  --status todo \
  --assignee-agent-id "$PAPERCLIP_AGENT_ID"
```

2. Trigger and watch a heartbeat for that assignee:

```bash
npx paperclipai heartbeat run --agent-id "$PAPERCLIP_AGENT_ID"
```

3. Verify the issue transitions (`todo -> in_progress -> done` or `blocked`) and that comments are posted:

```bash
npx paperclipai issue get <issue-id-or-identifier>
```

4. Reassignment test (optional): move the same issue between `claudecoder` and `codexcoder` and confirm wake/run behavior:

```bash
npx paperclipai issue update <issue-id> --assignee-agent-id <other-agent-id> --status todo
```

5. Cleanup: mark temporary issues done/cancelled with a clear note.

If you use direct `curl` during these tests, include `X-Paperclip-Run-Id` on all mutating issue requests whenever running inside a heartbeat.

## Full Reference

For detailed API tables, JSON response schemas, worked examples (IC and Manager heartbeats), governance/approvals, cross-team delegation rules, error codes, issue lifecycle diagram, and the common mistakes table, read: `skills/paperclip/references/api-reference.md`
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/api-reference.md"},{"kind":"reference","path":"references/company-skills.md"},{"kind":"reference","path":"references/routines.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.381Z$paperclip$, $paperclip$2026-04-08T22:19:26.758Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.execution_workspaces (1 rows)
INSERT INTO "public"."execution_workspaces" ("id", "company_id", "project_id", "project_workspace_id", "source_issue_id", "mode", "strategy_type", "name", "status", "cwd", "repo_url", "base_ref", "branch_name", "provider_type", "provider_ref", "derived_from_execution_workspace_id", "last_used_at", "opened_at", "closed_at", "cleanup_eligible_at", "cleanup_reason", "metadata", "created_at", "updated_at") VALUES ($paperclip$1e0a60b4-b4d8-45ac-bb5d-a791505605e0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$shared_workspace$paperclip$, $paperclip$project_primary$paperclip$, $paperclip$FOR-1$paperclip$, $paperclip$active$paperclip$, $paperclip$/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default$paperclip$, NULL, NULL, NULL, $paperclip$local_fs$paperclip$, NULL, NULL, $paperclip$2026-04-08T22:07:35.426Z$paperclip$, $paperclip$2026-04-08T22:07:35.426Z$paperclip$, NULL, NULL, NULL, $paperclip${"source":"project_primary","createdByRuntime":false}$paperclip$, $paperclip$2026-04-08T22:07:35.427Z$paperclip$, $paperclip$2026-04-08T22:07:35.427Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.heartbeat_run_events (41 rows)
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$8755c73e-6aa9-416c-bc31-59bd7a7bc12d$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:07:35.500Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$8755c73e-6aa9-416c-bc31-59bd7a7bc12d$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$error$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$Command not found in PATH: "agent"$paperclip$, NULL, $paperclip$2026-04-08T22:07:35.531Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.364Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"openclaw agent --session-id paperclip-p21-openclaw -m \"Reply with exactly OPENCLAW_OK and nothing else.\""},"command":"openclaw agent --session-id paperclip-p21-openclaw -m \"Reply with exactly OPENCLAW_OK and nothing else.\"","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:08:35.368Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$error$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.382Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.434Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"openclaw agent --session-id paperclip-p21-openclaw -m \"Reply with exactly OPENCLAW_OK and nothing else.\""},"command":"openclaw agent --session-id paperclip-p21-openclaw -m \"Reply with exactly OPENCLAW_OK and nothing else.\"","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:08:35.440Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$error$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.447Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:08:56.184Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$10$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK"},"command":"openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:08:56.186Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$11$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$error$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip$2026-04-08T22:08:56.191Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$12$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:09:17.080Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$14$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:09:37.941Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$17$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:11:31.643Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$18$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:12:14.409Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$13$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:09:17.082Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$15$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:11:22.194Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$23$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:13:27.306Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$27$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:14:39.376Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$36$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:18:02.830Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$40$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","OPENCLAW_GATEWAY_URL":"http://127.0.0.1:9","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:19:26.769Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$16$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:11:22.195Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$30$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:14:57.295Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$32$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:15:06.212Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$35$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T22:15:33.646Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$38$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:19:10.367Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$19$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:12:14.411Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$20$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:12:41.911Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$21$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:12:59.838Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$41$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T22:19:42.042Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$22$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","OPENCLAW_GATEWAY_URL":"http://127.0.0.1:9","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:12:59.840Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$25$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","OPENCLAW_GATEWAY_URL":"http://127.0.0.1:9","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:14:23.277Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$24$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:14:23.274Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$31$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:14:57.296Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$26$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T22:14:37.699Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$28$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:14:39.380Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$37$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:18:02.838Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$39$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:19:26.766Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$29$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T22:14:46.836Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$33$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T22:15:16.343Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$34$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","OPENCLAW_GATEWAY_URL":"http://127.0.0.1:9","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T22:15:16.345Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.heartbeat_runs (14 rows)
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$7bbd677d-cc69-48f2-b270-329bcd81f5bd$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:08:35.411Z$paperclip$, $paperclip$2026-04-08T22:08:35.446Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:08:35.346Z$paperclip$, $paperclip$2026-04-08T22:08:35.446Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$47a83a7e-08ff-47f4-9674-e65444d0f8a1$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/7bbd677d-cc69-48f2-b270-329bcd81f5bd.ndjson$paperclip$, $paperclip$308$paperclip$, $paperclip$2104efcc0adb2b7379dc28ab5362b3e0600608057c080e4e8451c0b6e3906482$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
$paperclip$, $paperclip$$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$assignment$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:08:35.349Z$paperclip$, $paperclip$2026-04-08T22:08:35.377Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m "Reply with exactly OPENCLAW_OK and nothing else."" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip${"source":"issue.create","taskId":"edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be","issueId":"edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be","taskKey":"edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be","wakeReason":"issue_assigned","wakeSource":"assignment","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:08:35.344Z$paperclip$, $paperclip$2026-04-08T22:08:35.377Z$paperclip$, $paperclip$system$paperclip$, $paperclip$595476a9-e638-4ebc-b8a7-026774a7dca4$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/4c8ef1da-f9fa-46bf-aeb2-cf8f8bf2a4c0.ndjson$paperclip$, $paperclip$503$paperclip$, $paperclip$c4d1a7f763bf1c8aefafb197410e1e18ef758a86e159c0722c0e46d0700c8905$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
[paperclip] Skipping saved session resume for task "edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be" because wake reason is issue_assigned.
$paperclip$, $paperclip$$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$8755c73e-6aa9-416c-bc31-59bd7a7bc12d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$assignment$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:07:35.334Z$paperclip$, $paperclip$2026-04-08T22:07:35.528Z$paperclip$, $paperclip$Command not found in PATH: "agent"$paperclip$, NULL, $paperclip${"source":"issue.create","taskId":"b7119a46-e4d8-4990-8745-ae4af3e76ea8","issueId":"b7119a46-e4d8-4990-8745-ae4af3e76ea8","taskKey":"b7119a46-e4d8-4990-8745-ae4af3e76ea8","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","wakeReason":"issue_assigned","wakeSource":"assignment","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default","mode":"shared_workspace","source":"project_primary","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[],"executionWorkspaceId":"1e0a60b4-b4d8-45ac-bb5d-a791505605e0"}$paperclip$, $paperclip$2026-04-08T22:07:35.318Z$paperclip$, $paperclip$2026-04-08T22:07:35.528Z$paperclip$, $paperclip$system$paperclip$, $paperclip$34e19f14-7f5b-4dac-b3eb-40b5c934231e$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/8755c73e-6aa9-416c-bc31-59bd7a7bc12d.ndjson$paperclip$, $paperclip$934$paperclip$, $paperclip$7bebb3c2eb7c517c35c11f97bc6e4d2927d2e17ad2c21e4fbbbd4906f21ada8b$paperclip$, false, $paperclip$[paperclip] Skipping saved session resume for task "b7119a46-e4d8-4990-8745-ae4af3e76ea8" because wake reason is issue_assigned.
$paperclip$, $paperclip$[paperclip] Injected Cursor skill "paperclipai/paperclip/paperclip" into /Users/jonathanborgia/.cursor/skills
[paperclip] Injected Cursor skill "paperclipai/paperclip/paperclip-create-agent" into /Users/jonathanborgia/.cursor/skills
[paperclip] Injected Cursor skill "paperclipai/paperclip/paperclip-create-plugin" into /Users/jonathanborgia/.cursor/skills
[paperclip] Injected Cursor skill "paperclipai/paperclip/para-memory-files" into /Users/jonathanborgia/.cursor/skills
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$964cdfbf-3936-4823-89d9-386c7ad223ba$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:08:56.171Z$paperclip$, $paperclip$2026-04-08T22:08:56.189Z$paperclip$, $paperclip$Failed to start command "openclaw agent --session-id paperclip-p21-openclaw -m OPENCLAW_OK" in "/Users/jonathanborgia/foreman-git/foreman-v2". Verify adapter command, working directory, and PATH (/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin:/Users/jonathanborgia/foreman-git/foreman-v2/node_modules/.bin:/Users/jonathanborgia/foreman-git/node_modules/.bin:/Users/jonathanborgia/node_modules/.bin:/Users/node_modules/.bin:/node_modules/.bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Users/jonathanborgia/.opencode/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/opt/openjdk/bin:/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin).$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:08:56.169Z$paperclip$, $paperclip$2026-04-08T22:08:56.189Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$d52ca3ac-3f8a-44ad-9a75-84b52e104365$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/964cdfbf-3936-4823-89d9-386c7ad223ba.ndjson$paperclip$, $paperclip$308$paperclip$, $paperclip$049bc90f2366b2a0503eaea2a4027084540156fc0f3269862180afbcfb2670f4$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
$paperclip$, $paperclip$$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$b35e4a63-4464-4963-a960-83e45dc8bf95$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:11:22.183Z$paperclip$, $paperclip$2026-04-08T22:11:31.639Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:11:22.179Z$paperclip$, $paperclip$2026-04-08T22:11:31.639Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$d352c40a-322c-47b4-94c8-e668d84877db$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"completed\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/b35e4a63-4464-4963-a960-83e45dc8bf95.ndjson$paperclip$, $paperclip$382$paperclip$, $paperclip$20752b48e02f076d2d24bab9e45651dcf02a4df111a91d58ca742851aa90ca6b$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
completed
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$fc742a87-70b0-4438-99fd-7757eb7872c1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:09:17.072Z$paperclip$, $paperclip$2026-04-08T22:09:37.936Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:09:17.070Z$paperclip$, $paperclip$2026-04-08T22:09:37.936Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$ea858066-be90-469d-b75f-45d8d7da68ef$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"completed\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/fc742a87-70b0-4438-99fd-7757eb7872c1.ndjson$paperclip$, $paperclip$382$paperclip$, $paperclip$0507d986f79a39b98e04d0e586e061b0ae9e3e7d949ff2ca005a99d20608cb38$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
completed
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$21c5efb0-238f-471f-9bc0-ec75747fb633$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:12:14.397Z$paperclip$, $paperclip$2026-04-08T22:12:41.908Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:12:14.394Z$paperclip$, $paperclip$2026-04-08T22:12:41.908Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$a2066733-2ce3-4457-8bb8-5a4cc50828c9$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"I need to know which channel you'd like me to use for messaging. Common options include Discord, Telegram, WhatsApp, or your default webchat. Please let me know your preferred channel or provide the specific channel name/ID.\n⚠️ ✉️ Message failed\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/21c5efb0-238f-471f-9bc0-ec75747fb633.ndjson$paperclip$, $paperclip$690$paperclip$, $paperclip$f2db550a969d5e0d5c9d268b22d07e102f94807a144e1247a3874dbcd707b5d1$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
I need to know which channel you'd like me to use for messaging. Common options include Discord, Telegram, WhatsApp, or your default webchat. Please let me know your preferred channel or provide the specific channel name/ID.
⚠️ ✉️ Message failed
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$11c1d128-82d3-4d27-a98c-3d2b9cf24c71$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:19:26.752Z$paperclip$, $paperclip$2026-04-08T22:19:42.039Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:19:26.749Z$paperclip$, $paperclip$2026-04-08T22:19:42.039Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$ca355930-a461-4cbb-9873-71a5f3c98211$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: OpenClaw gateway path failed; refusing silent fallback.\n","stdout":""}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/11c1d128-82d3-4d27-a98c-3d2b9cf24c71.ndjson$paperclip$, $paperclip$435$paperclip$, $paperclip$1542cfe25fa9402a7fadfe72468af06497046c2b8dbb4450a2b45b57dd8d0262$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
$paperclip$, $paperclip$ERROR: OpenClaw gateway path failed; refusing silent fallback.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$76e7bd4a-5198-41d9-ad4a-340e7f00cd66$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:12:59.827Z$paperclip$, $paperclip$2026-04-08T22:13:27.303Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:12:59.824Z$paperclip$, $paperclip$2026-04-08T22:13:27.303Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$8ea15f90-70d3-41a3-859b-08a3ada480e5$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials\nFix: pass --token or --password (or gatewayToken in tools).\nConfig: /Users/jonathanborgia/.openclaw/openclaw.json\n","stdout":"[agents] synced openai-codex credentials from external cli\nNo reply from agent.\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/76e7bd4a-5198-41d9-ad4a-340e7f00cd66.ndjson$paperclip$, $paperclip$802$paperclip$, $paperclip$4bccb52c6e0f6fd6e73445c83189e85310332b835292912db425589058dd2065$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
[agents] synced openai-codex credentials from external cli
No reply from agent.
$paperclip$, $paperclip$Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials
Fix: pass --token or --password (or gatewayToken in tools).
Config: /Users/jonathanborgia/.openclaw/openclaw.json
$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$d478daab-e915-4d17-9efe-3cf2afdf529b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:14:23.262Z$paperclip$, $paperclip$2026-04-08T22:14:37.697Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:14:23.258Z$paperclip$, $paperclip$2026-04-08T22:14:37.697Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$aa4ceb3a-48f0-49ce-9d03-e2bbb1e2b529$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: OpenClaw gateway path failed; refusing silent fallback.\n","stdout":"Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials\nFix: pass --token or --password (or gatewayToken in tools).\nConfig: /Users/jonathanborgia/.openclaw/openclaw.json\n[agents] synced openai-codex credentials from external cli\nHEARTBEAT_OK\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/d478daab-e915-4d17-9efe-3cf2afdf529b.ndjson$paperclip$, $paperclip$795$paperclip$, $paperclip$bc7d0cdf2b9a898c512956c1f305e9b9144e4f948d22993e3944383a53cbc0f9$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials
Fix: pass --token or --password (or gatewayToken in tools).
Config: /Users/jonathanborgia/.openclaw/openclaw.json
[agents] synced openai-codex credentials from external cli
HEARTBEAT_OK
$paperclip$, $paperclip$ERROR: OpenClaw gateway path failed; refusing silent fallback.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$14582c91-7c68-42e0-9c2f-9f3cf6f9668d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:14:39.360Z$paperclip$, $paperclip$2026-04-08T22:14:46.834Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:14:39.355Z$paperclip$, $paperclip$2026-04-08T22:14:46.834Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$4c365f0a-ba4a-4988-bac8-744ae3808a40$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/14582c91-7c68-42e0-9c2f-9f3cf6f9668d.ndjson$paperclip$, $paperclip$385$paperclip$, $paperclip$8212e3a1151b647726fc7faec042ef8d9f0dfad44b65c9fbdd87fd5eec15a97a$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ef7519eb-fa3d-4edc-9310-e166eae986d7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:14:57.286Z$paperclip$, $paperclip$2026-04-08T22:15:06.208Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:14:57.283Z$paperclip$, $paperclip$2026-04-08T22:15:06.208Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$2e706ba7-4f6d-470a-b3ef-8c0240c200ef$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/ef7519eb-fa3d-4edc-9310-e166eae986d7.ndjson$paperclip$, $paperclip$385$paperclip$, $paperclip$c85ab6e34c4b7d380de2f2edc1870ab56c96a83a9b08ba5573c9ed4a80fbfc71$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$6843be8c-954e-4adc-8f03-cf216d84b5a7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T22:15:16.335Z$paperclip$, $paperclip$2026-04-08T22:15:33.642Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:15:16.333Z$paperclip$, $paperclip$2026-04-08T22:15:33.642Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$1ce55dc2-25eb-4309-ab8b-7fac581e960a$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: OpenClaw gateway path failed; refusing silent fallback.\n","stdout":"Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials\nFix: pass --token or --password (or gatewayToken in tools).\nConfig: /Users/jonathanborgia/.openclaw/openclaw.json\n[agents] synced openai-codex credentials from external cli\nHEARTBEAT_OK\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/6843be8c-954e-4adc-8f03-cf216d84b5a7.ndjson$paperclip$, $paperclip$795$paperclip$, $paperclip$66f6e1306f6186ce072c82bdcfa2b466c0757c4e4f0e87eddc9bf3e9610a28f2$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
Gateway agent failed; falling back to embedded: Error: gateway url override requires explicit credentials
Fix: pass --token or --password (or gatewayToken in tools).
Config: /Users/jonathanborgia/.openclaw/openclaw.json
[agents] synced openai-codex credentials from external cli
HEARTBEAT_OK
$paperclip$, $paperclip$ERROR: OpenClaw gateway path failed; refusing silent fallback.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ee97b599-475d-41d0-895b-478bee5b3d84$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T22:18:02.806Z$paperclip$, $paperclip$2026-04-08T22:19:10.364Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T22:18:02.791Z$paperclip$, $paperclip$2026-04-08T22:19:10.364Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$305eb2f0-e7e3-47ac-9b26-e555fad5811e$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/ee97b599-475d-41d0-895b-478bee5b3d84.ndjson$paperclip$, $paperclip$385$paperclip$, $paperclip$b2978541320d8a15742f155cd7a941a78bc03c7843ed2b895822dec5065131bb$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.instance_settings (1 rows)
INSERT INTO "public"."instance_settings" ("id", "singleton_key", "experimental", "created_at", "updated_at", "general") VALUES ($paperclip$a6f3130b-0615-4501-93f7-b231b1cee76e$paperclip$, $paperclip$default$paperclip$, $paperclip${}$paperclip$, $paperclip$2026-04-08T22:06:20.136Z$paperclip$, $paperclip$2026-04-08T22:06:20.136Z$paperclip$, $paperclip${}$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.instance_user_roles (1 rows)
INSERT INTO "public"."instance_user_roles" ("id", "user_id", "role", "created_at", "updated_at") VALUES ($paperclip$e15abad1-c181-45dc-99ec-d06f64cbbd05$paperclip$, $paperclip$local-board$paperclip$, $paperclip$instance_admin$paperclip$, $paperclip$2026-04-08T22:06:07.131Z$paperclip$, $paperclip$2026-04-08T22:06:07.131Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.issue_read_states (1 rows)
INSERT INTO "public"."issue_read_states" ("id", "company_id", "issue_id", "user_id", "last_read_at", "created_at", "updated_at") VALUES ($paperclip$ea6972c0-43e5-4ccf-a8df-70ed262a8006$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T22:07:35.636Z$paperclip$, $paperclip$2026-04-08T22:07:35.639Z$paperclip$, $paperclip$2026-04-08T22:07:35.636Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.issues (2 rows)
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, NULL, $paperclip$Hire your first engineer and create a hiring plan$paperclip$, $paperclip$You are the CEO. You set the direction for the company.

- hire a founding engineer
- write a hiring plan
- break the roadmap into concrete tasks and start delegating work$paperclip$, $paperclip$todo$paperclip$, $paperclip$medium$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T22:07:35.301Z$paperclip$, $paperclip$2026-04-08T22:07:35.533Z$paperclip$, 1, $paperclip$FOR-1$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, NULL, NULL, $paperclip$P2.1 minimal OpenClaw seam proof$paperclip$, $paperclip$Trigger one Paperclip heartbeat that executes OpenClaw as the runtime adapter and returns OPENCLAW_OK.$paperclip$, $paperclip$todo$paperclip$, $paperclip$high$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T22:08:35.338Z$paperclip$, $paperclip$2026-04-08T22:08:35.385Z$paperclip$, 2, $paperclip$FOR-2$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.principal_permission_grants (2 rows)
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$8673791c-9f87-42a8-ab28-88b8cf667276$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T22:07:24.534Z$paperclip$, $paperclip$2026-04-08T22:07:24.534Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$cfff51aa-ba79-41ca-bbfc-30f0d925034b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T22:08:35.336Z$paperclip$, $paperclip$2026-04-08T22:08:35.336Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.projects (1 rows)
INSERT INTO "public"."projects" ("id", "company_id", "goal_id", "name", "description", "status", "lead_agent_id", "target_date", "created_at", "updated_at", "color", "archived_at", "execution_workspace_policy", "pause_reason", "paused_at") VALUES ($paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, $paperclip$Onboarding$paperclip$, NULL, $paperclip$in_progress$paperclip$, NULL, NULL, $paperclip$2026-04-08T22:07:35.283Z$paperclip$, $paperclip$2026-04-08T22:07:35.283Z$paperclip$, $paperclip$#6366f1$paperclip$, NULL, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.user (1 rows)
INSERT INTO "public"."user" ("id", "name", "email", "email_verified", "image", "created_at", "updated_at") VALUES ($paperclip$local-board$paperclip$, $paperclip$Board$paperclip$, $paperclip$local@paperclip.local$paperclip$, true, NULL, $paperclip$2026-04-08T22:06:07.111Z$paperclip$, $paperclip$2026-04-08T22:06:07.111Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Sequence values
SELECT setval('"public"."heartbeat_run_events_id_seq"', 41, true);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

COMMIT;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
