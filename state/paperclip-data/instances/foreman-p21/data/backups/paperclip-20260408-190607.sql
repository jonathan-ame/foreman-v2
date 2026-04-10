-- Paperclip database backup
-- Created: 2026-04-09T01:06:07.197Z

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

-- Data for: public.activity_log (137 rows)
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
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$cebf714d-3a50-48fb-a0d5-a61b2b5c0fb7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType"],"changedAdapterConfigKeys":["command","cwd","env","graceSec","instructionsBundleMode","instructionsEntryFile","instructionsFilePath","instructionsRootPath","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T23:27:06.161Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$a3aa164d-d8d1-45ec-a64c-a792935eecd9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T23:27:06.166Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$863e6204-bf10-41a7-a09b-85d1b9567503$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, NULL, $paperclip${"name":"EmbeddingWorker","role":"engineer","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T23:27:06.177Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$5768a2b8-3f8a-4101-b5b0-e4ed6d1520cc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:27:14.108Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$029a3f25-c4aa-4f07-8a90-5e051cf7eea2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:37:20.072Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$8222806e-eb09-413e-8353-55ceecfc1116$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:27:26.181Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$6cc144e5-0f7f-4810-b0b4-6ba294f217e3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:27:28.210Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$2ad467ae-fa01-489e-a9b6-69d2ae4b0c5e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T23:27:48.755Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$76f00b1d-14a6-453e-8073-a4868d73c678$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:27:48.763Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$f05111ab-2120-445a-bded-48614ab1cdb3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-08T23:27:50.792Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$142230a4-bd6d-42c4-8f47-5828eaf98404$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:27:50.806Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$42e43d17-438d-4dc4-8d50-83929c51997a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, NULL, $paperclip${"name":"ChiefOfStaff","role":"general","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T23:41:48.588Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$51411fb7-0b19-4364-a7f7-401bf686a099$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:34:06.946Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d48839ff-2f6e-4809-b4a5-27df028309a3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:34:17.001Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d9c5574c-892e-41f2-9d87-243b97aef468$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$265c953e-789f-41d2-a483-20c71c0430bf$paperclip$, NULL, $paperclip${"name":"QAEngineer","role":"qa","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T23:41:48.612Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$eb0280a6-876c-4f96-870a-55cab297fac6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, NULL, $paperclip${"title":"B3.4 delegated workflow parent task","identifier":"FOR-3"}$paperclip$, $paperclip$2026-04-08T23:42:07.103Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$0b5bac41-ab31-4f63-804c-c9e502890803$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, NULL, $paperclip${"agentId":"788dfd8a-d944-4a3c-a1be-a8d30bb1dfde"}$paperclip$, $paperclip$2026-04-08T23:42:07.156Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$b0908438-9fac-4482-a6bd-a1f83299c880$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:34:19.039Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4632b84f-02a4-49fb-8475-052c4a43d2cd$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:37:05.984Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4ee16969-9efd-412d-8599-7945ce0168c1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:37:18.045Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$73520119-2b5d-4fde-b5da-0d1676e1ae24$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, NULL, $paperclip${"name":"EngineeringBuilder","role":"engineer","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T23:41:48.598Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$32b9c8a1-ced3-43e0-8719-62165a17117a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$e486e9c1-7fb6-4671-b1db-3f0d66c19121$paperclip$, NULL, $paperclip${"name":"DevOpsAgent","role":"devops","desiredSkills":null}$paperclip$, $paperclip$2026-04-08T23:41:48.605Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$dbeb0950-4fed-4df5-80a4-f34c0694992a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$6e292396-541e-424d-b5a7-229ea9408ad2$paperclip$, NULL, $paperclip${"title":"B3.4 delegated workflow child task","identifier":"FOR-4"}$paperclip$, $paperclip$2026-04-08T23:42:07.110Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$edba08b4-0753-48d0-a2a4-5fb1dfa49d5f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.comment_added$paperclip$, $paperclip$issue$paperclip$, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, NULL, $paperclip${"commentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","identifier":"FOR-3","issueTitle":"B3.4 delegated workflow parent task","bodySnippet":"Delegated implementation to EngineeringBuilder via child issue FOR-4"}$paperclip$, $paperclip$2026-04-08T23:42:07.129Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$b7c11a84-676e-44bb-80a4-c841f26c8527$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:45:15.605Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$74ed3e1f-f541-4883-8eb4-c7d84b798c12$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:45:29.695Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$460baeff-f569-4fad-9014-45157d5e6a5e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:45:31.729Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$114e4f7d-2749-43c2-a534-9233198f2a19$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:47:13.048Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$3d739316-d912-4b8c-8d32-d8c789aa0a36$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:47:25.109Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$ad366aa7-d26f-4489-8f6f-c9870d589e83$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:47:27.141Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9ad9c451-0f0b-4f2a-93e5-7c1a5635496a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:49:25.806Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1b4912b0-8487-4f7b-953c-ad6ccd8b2040$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:49:37.872Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$f314c83b-b862-4976-8b3b-34c322d82130$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, NULL, $paperclip${"agentId":"b82a9601-f0c3-41b5-9a15-571d868b6b1e"}$paperclip$, $paperclip$2026-04-08T23:49:54.936Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$6948c334-f765-4859-af05-65f4cc4cbc52$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, NULL, $paperclip${"agentId":"94183066-a375-4870-be76-062cc80f34ce"}$paperclip$, $paperclip$2026-04-08T23:50:05.015Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9e31dac3-2505-43bb-9369-a15de441cb38$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, NULL, $paperclip${"agentId":"865d128d-1e01-4daa-b571-f61b81d31097"}$paperclip$, $paperclip$2026-04-08T23:50:07.047Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$95fcd064-e7e6-4d16-bf57-6f5373226573$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, NULL, $paperclip${"agentId":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e"}$paperclip$, $paperclip$2026-04-08T23:57:13.444Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$80da6ed7-479b-4940-a8fe-01e07d582d27$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, NULL, $paperclip${"agentId":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e"}$paperclip$, $paperclip$2026-04-08T23:59:52.802Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$8175066e-b0e2-47b5-adce-96522d9d75ab$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, NULL, $paperclip${"agentId":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e"}$paperclip$, $paperclip$2026-04-09T00:01:27.451Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$aeb81346-f644-4345-843b-ebb7f4702ea2$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$company.created$paperclip$, $paperclip$company$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, NULL, $paperclip${"name":"Foreman-Isolation-B"}$paperclip$, $paperclip$2026-04-09T00:06:05.035Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$ab53fa5e-f152-44bf-89bd-02b168821b82$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$4e6fc7c9-51b2-43db-9cb9-fc97645e30fb$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693165","identifier":"FOR-5"}$paperclip$, $paperclip$2026-04-09T00:06:05.046Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$e2c40cae-f924-4934-9432-e52643ea538d$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$691f08c7-71ea-42ad-a938-1a27298d564b$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693165","identifier":"FORA-1"}$paperclip$, $paperclip$2026-04-09T00:06:05.053Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9a5e663b-f8d5-4240-871b-7e374e2f9b1d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$f36f37fb-bfd7-4e75-84a5-1fdb3dd19c90$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693297","identifier":"FOR-6"}$paperclip$, $paperclip$2026-04-09T00:08:17.068Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$948cc0dd-2451-446f-8489-7c194c76f2f2$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$91e4551c-5c8d-42e8-bc6e-37713b3751f4$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693297","identifier":"FORA-2"}$paperclip$, $paperclip$2026-04-09T00:08:17.072Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$59666a10-6e7b-4d27-9960-f82346a5ba2b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$35d179e8-4be1-4407-84b5-39f0016994e0$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693445","identifier":"FOR-7"}$paperclip$, $paperclip$2026-04-09T00:10:45.569Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$99b8f2a1-8e55-4109-830c-4128a42ba109$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$3dfab48c-cbf8-4999-b1ab-9b21bee0decb$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693445","identifier":"FORA-3"}$paperclip$, $paperclip$2026-04-09T00:10:45.582Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$7fb20375-71a8-46bc-b099-253a276b386b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$35d179e8-4be1-4407-84b5-39f0016994e0$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:10:45.603Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$6b8228c3-0295-445c-b353-c6f3a738342a$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$3dfab48c-cbf8-4999-b1ab-9b21bee0decb$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:10:45.610Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4c73061b-f1d7-44af-a4e7-d672a78710f4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$587024e1-3d22-4e1d-a0cc-6c1714f2c8d5$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693536","identifier":"FOR-8"}$paperclip$, $paperclip$2026-04-09T00:12:16.450Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9a1a2dc1-50c5-4938-a244-69ebf9f18139$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$0e4b2896-86f2-44ae-9593-7a2fba19f854$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693536","identifier":"FORA-4"}$paperclip$, $paperclip$2026-04-09T00:12:16.455Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1413f716-d98e-4407-8917-4c84dd6a220f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$587024e1-3d22-4e1d-a0cc-6c1714f2c8d5$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:12:16.463Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$d0268c43-32c1-40fe-8e33-0098bf9dbc43$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$0e4b2896-86f2-44ae-9593-7a2fba19f854$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:12:16.468Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$020465e1-56b7-4c89-a2c7-c68d79cae106$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$54360060-93f3-4525-bd5a-8f34ec82c798$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693654","identifier":"FOR-9"}$paperclip$, $paperclip$2026-04-09T00:14:14.511Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$83c2c71e-ddb8-4188-a63b-e6dd1b2ab4c2$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$7cde4254-bcef-4fc5-b3f5-fe6a2489b022$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693654","identifier":"FORA-5"}$paperclip$, $paperclip$2026-04-09T00:14:14.515Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$047dad79-c385-443a-9824-f197817aca75$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$54360060-93f3-4525-bd5a-8f34ec82c798$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:14:14.525Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$82d35427-dd5d-4ff8-9b80-46d8b7893df3$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$7cde4254-bcef-4fc5-b3f5-fe6a2489b022$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:14:14.530Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$bdfa4333-d951-4099-84d9-edd336d812c9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$774484a3-69d9-41b3-816a-6c1987066f07$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693729","identifier":"FOR-10"}$paperclip$, $paperclip$2026-04-09T00:15:29.291Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$3af2efad-ce86-4250-b78b-efc65ef846c5$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$8e4a14f1-45a1-44a0-b2fa-39927418141d$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693729","identifier":"FORA-6"}$paperclip$, $paperclip$2026-04-09T00:15:29.295Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$97978939-ec86-431b-9be6-c14f62b0a114$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$8e4a14f1-45a1-44a0-b2fa-39927418141d$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:15:29.308Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$2366deb2-3ef6-4310-9512-da6a9ab9cb1b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$ab5f23a9-2240-46c2-9968-3132d0142772$paperclip$, NULL, $paperclip${"title":"isolation-a-1775693826","identifier":"FOR-11"}$paperclip$, $paperclip$2026-04-09T00:17:06.334Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9b4b2fa4-79c1-4476-a8ea-1d11269340d4$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$8dc1b742-ef45-4ccb-9137-f17cdd54bf20$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:17:06.350Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$a754aabe-4dfc-468e-9823-ae2bd0ebd96a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$774484a3-69d9-41b3-816a-6c1987066f07$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:15:29.304Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$5de545e0-7962-4969-bde3-459c1616ad8e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.deleted$paperclip$, $paperclip$issue$paperclip$, $paperclip$ab5f23a9-2240-46c2-9968-3132d0142772$paperclip$, NULL, NULL, $paperclip$2026-04-09T00:17:06.345Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$f534d038-dc5f-44e6-93d2-811c6bb57837$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, NULL, $paperclip${"agentId":"4cfa9f9c-5211-4182-a630-f389ed61a3f4"}$paperclip$, $paperclip$2026-04-09T00:22:07.817Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$bd7c316f-a7c6-49ec-9a54-7106e2d03023$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, NULL, $paperclip${"name":"ProductLeadChief","role":"pm","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:41:42.037Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$77e5915a-24e1-4d17-be70-f3efcac5ae5b$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.created$paperclip$, $paperclip$issue$paperclip$, $paperclip$8dc1b742-ef45-4ccb-9137-f17cdd54bf20$paperclip$, NULL, $paperclip${"title":"isolation-b-1775693826","identifier":"FORA-7"}$paperclip$, $paperclip$2026-04-09T00:17:06.338Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1e44accb-b013-4953-a428-fd65d51d4f83$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, NULL, $paperclip${"agentId":"7a2913ec-480f-40a2-920a-a047bc578025"}$paperclip$, $paperclip$2026-04-09T00:41:42.058Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9814b76b-5263-4c9e-891b-9f697634a962$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, NULL, $paperclip${"agentId":"9090f2f8-0164-4ae7-8a0b-869ab02a9f1e"}$paperclip$, $paperclip$2026-04-09T00:41:52.124Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$19638f3d-ff5a-4518-999f-58f4cf57b68f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, NULL, $paperclip${"agentId":"837263a1-004a-4baa-b7ad-3d6b6a63a464"}$paperclip$, $paperclip$2026-04-09T00:42:08.261Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$57c29eec-80c0-4570-9fd4-3ef5593f925d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, NULL, $paperclip${"name":"ReviewScriptAuditor","role":"qa","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:20:03.190Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$10407ac7-cb5f-4e4e-a432-32218910cf85$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, NULL, $paperclip${"name":"ReviewCostInfra","role":"devops","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:20:03.200Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$9aee9638-d519-44bf-a707-8b0c1cc354fb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, NULL, $paperclip${"agentId":"c3c73efe-163e-4e63-9fd0-1286b4abf4cb"}$paperclip$, $paperclip$2026-04-09T00:20:29.251Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$87b2ef85-82ce-4518-a285-ff94b82b475a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, NULL, $paperclip${"agentId":"442238da-cff2-4ac3-b9b9-d5de8c66f1fc"}$paperclip$, $paperclip$2026-04-09T00:20:41.348Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4de6ecb5-ab91-48fd-899b-f981853950cf$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, NULL, $paperclip${"agentId":"58be556b-c711-47a6-8339-a8df890bb083"}$paperclip$, $paperclip$2026-04-09T00:42:00.185Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$29198baa-504f-4195-b239-829ece47efd6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, NULL, $paperclip${"name":"ReviewLicense","role":"general","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:20:03.205Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c121e81d-e374-4529-92ca-177ff9cc274a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, NULL, $paperclip${"name":"ReviewPhaseBoundary","role":"pm","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:20:03.210Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$662bf0ad-3813-4553-bd8c-7326916ef260$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, NULL, $paperclip${"agentId":"741f87c4-b981-4c85-8e3b-1ca97ff20df8"}$paperclip$, $paperclip$2026-04-09T00:21:21.603Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$0a34e44b-8aa5-4da6-a086-52576b6d7842$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$issue.read_marked$paperclip$, $paperclip$issue$paperclip$, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, NULL, $paperclip${"userId":"local-board","lastReadAt":"2026-04-09T00:39:56.060Z"}$paperclip$, $paperclip$2026-04-09T00:39:56.064Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$529ca206-cbc6-40be-a49e-e316491696f5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, NULL, $paperclip${"name":"LegalComplianceChief","role":"general","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:41:42.041Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$5d26d1f6-d36d-49ab-b18f-3c5a7684cc38$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, NULL, $paperclip${"name":"FinanceChief","role":"cfo","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:41:42.045Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$a71ad4ef-3fbe-488b-9c83-8c4875b0ae6c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, NULL, $paperclip${"name":"GrowthChief","role":"cmo","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:41:42.048Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$8c32c462-59bf-4d85-a701-a8d59b7f31ab$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, NULL, $paperclip${"agentId":"7a2913ec-480f-40a2-920a-a047bc578025"}$paperclip$, $paperclip$2026-04-09T00:44:04.316Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c296baac-641b-4d4b-a664-97c652061102$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, NULL, $paperclip${"agentId":"9090f2f8-0164-4ae7-8a0b-869ab02a9f1e"}$paperclip$, $paperclip$2026-04-09T00:44:16.384Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$ee457634-97e6-4131-93a5-a145ae391e44$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, NULL, $paperclip${"agentId":"58be556b-c711-47a6-8339-a8df890bb083"}$paperclip$, $paperclip$2026-04-09T00:44:24.444Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4abb5468-58a4-466e-9ed9-19ba43029695$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, NULL, $paperclip${"agentId":"837263a1-004a-4baa-b7ad-3d6b6a63a464"}$paperclip$, $paperclip$2026-04-09T00:44:32.503Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$a56b630c-79e8-4e20-88cd-dd24e9f8d19e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, NULL, $paperclip${"name":"ProductAnalyst","role":"pm","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:57:02.153Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$89aef809-cead-4997-8524-f3aa4d9a2d22$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, NULL, $paperclip${"agentId":"2d7912a1-d0be-41af-8c2c-d7786a761494"}$paperclip$, $paperclip$2026-04-09T00:57:02.180Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$0b6519b5-19ab-43fd-8394-3be0cd76829c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, NULL, $paperclip${"name":"ComplianceCounsel","role":"general","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:57:14.253Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$fb5789fc-aa90-4e16-8d30-bee29a54c22c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, NULL, $paperclip${"agentId":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66"}$paperclip$, $paperclip$2026-04-09T00:57:14.273Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$5fcada56-8b39-4542-8368-a3a37f34c00f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, NULL, $paperclip${"name":"BudgetAnalyst","role":"cfo","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:57:26.331Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c11a7fed-d632-48a2-af58-b02889da096b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, NULL, $paperclip${"agentId":"fc538926-ae82-4271-942d-079132c27cbc"}$paperclip$, $paperclip$2026-04-09T00:57:26.346Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$5b13a95e-3647-4bd0-8517-ae14e9be6dc6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.created$paperclip$, $paperclip$agent$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, NULL, $paperclip${"name":"DemandGenLead","role":"cmo","desiredSkills":null}$paperclip$, $paperclip$2026-04-09T00:57:38.404Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$2646ffb5-5314-427f-bed3-2949461dfe09$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, NULL, $paperclip${"agentId":"921a8222-e657-4233-9cf4-c7c9ccb98eb3"}$paperclip$, $paperclip$2026-04-09T00:57:38.420Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$c27d57e2-b36e-4e4c-9189-69ab10cb9f5b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T00:58:36.072Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$06a0ae9f-ec1a-4d2f-bef6-43e6b04a653c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, NULL, $paperclip${"agentId":"2d7912a1-d0be-41af-8c2c-d7786a761494"}$paperclip$, $paperclip$2026-04-09T00:58:36.099Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$e68acff9-b5c8-4e97-b061-4ef147e4500e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T00:58:46.179Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$e2a97382-6a7f-4ec0-b476-8fd59b7a06dd$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, NULL, $paperclip${"agentId":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66"}$paperclip$, $paperclip$2026-04-09T00:58:46.232Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1e2b2d2b-69b3-4906-b3e2-5ccc75b81444$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T00:58:58.285Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$73bb9e9a-61a7-4a39-9044-815702c89989$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, NULL, $paperclip${"agentId":"fc538926-ae82-4271-942d-079132c27cbc"}$paperclip$, $paperclip$2026-04-09T00:58:58.298Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$8f06f4c9-7f12-432f-9e32-78365972cf85$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T00:59:06.349Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$0e6e744f-bb68-41ee-90fa-4fc39672c084$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, NULL, $paperclip${"agentId":"921a8222-e657-4233-9cf4-c7c9ccb98eb3"}$paperclip$, $paperclip$2026-04-09T00:59:06.362Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$e855924c-8aaa-4bcd-b874-63fcb786ae51$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T01:01:10.112Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$4634fea6-52c1-4f66-b582-6fb7eec45032$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, NULL, $paperclip${"agentId":"2d7912a1-d0be-41af-8c2c-d7786a761494"}$paperclip$, $paperclip$2026-04-09T01:01:10.121Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$28812eb9-92b1-4253-9773-9d87bc151d0d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T01:01:18.159Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$1178a508-b836-4dea-84af-91b9c83b8a2b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, NULL, $paperclip${"agentId":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66"}$paperclip$, $paperclip$2026-04-09T01:01:18.170Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$3ceb5d39-54b6-4b7e-af13-d4475d580689$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T01:01:26.202Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$76252a4a-412c-49af-831e-065fac1f0f37$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, NULL, $paperclip${"agentId":"fc538926-ae82-4271-942d-079132c27cbc"}$paperclip$, $paperclip$2026-04-09T01:01:26.214Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$0deda674-969d-4efe-b320-bc7a74ca9a20$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$agent.updated$paperclip$, $paperclip$agent$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, NULL, $paperclip${"changedTopLevelKeys":["adapterConfig","adapterType","capabilities","name","reportsTo","role","title"],"changedAdapterConfigKeys":["command","cwd","env","timeoutSec"]}$paperclip$, $paperclip$2026-04-09T01:01:40.309Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."activity_log" ("id", "company_id", "actor_type", "actor_id", "action", "entity_type", "entity_id", "agent_id", "details", "created_at", "run_id") VALUES ($paperclip$134f212d-3daf-41d0-b4e6-44a15e07640c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$heartbeat.invoked$paperclip$, $paperclip$heartbeat_run$paperclip$, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, NULL, $paperclip${"agentId":"921a8222-e657-4233-9cf4-c7c9ccb98eb3"}$paperclip$, $paperclip$2026-04-09T01:01:40.321Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_config_revisions (14 rows)
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
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$adb66d13-436b-4365-abd3-db51e3ab54d1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"CEO","role":"ceo","title":null,"metadata":null,"reportsTo":null,"adapterType":"process","capabilities":"OpenClaw gateway-backed execution (RunPod-backed via Foreman config)","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","graceSec":15,"timeoutSec":240,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"},"runtimeConfig":{"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"CEO","role":"ceo","title":null,"metadata":null,"reportsTo":null,"adapterType":"process","capabilities":"OpenClaw gateway-backed execution (RunPod-backed via Foreman config)","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","graceSec":15,"timeoutSec":240,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"},"runtimeConfig":{"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T23:27:06.159Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$45e3bc64-e815-4860-b995-bad91109db47$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["capabilities","adapterConfig"]$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"OpenClaw gateway-backed execution","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"OpenClawWorker","role":"engineer","title":"OpenClaw Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"Role-dispatched planner runtime via role-routing source-of-truth","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"planner"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T23:27:06.165Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$a8d72825-29cb-4e4e-a363-4689a86f8567$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"EmbeddingWorker","role":"engineer","title":"Embedding Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"Role-dispatched embedding runtime via role-routing source-of-truth","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"embedding"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"EmbeddingWorker","role":"engineer","title":"Embedding Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"Role-dispatched embedding runtime via role-routing source-of-truth","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"invalid-role"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T23:27:48.754Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_config_revisions" ("id", "company_id", "agent_id", "created_by_agent_id", "created_by_user_id", "source", "rolled_back_from_revision_id", "changed_keys", "before_config", "after_config", "created_at") VALUES ($paperclip$0c09e940-61f1-4dba-ad3f-1445ad8ff412$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$patch$paperclip$, NULL, $paperclip$["adapterConfig"]$paperclip$, $paperclip${"name":"EmbeddingWorker","role":"engineer","title":"Embedding Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"Role-dispatched embedding runtime via role-routing source-of-truth","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"invalid-role"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip${"name":"EmbeddingWorker","role":"engineer","title":"Embedding Runtime Worker","metadata":null,"reportsTo":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","adapterType":"process","capabilities":"Role-dispatched embedding runtime via role-routing source-of-truth","adapterConfig":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"embedding"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180},"runtimeConfig":{},"budgetMonthlyCents":0}$paperclip$, $paperclip$2026-04-08T23:27:50.790Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_runtime_state (19 rows)
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.058Z$paperclip$, $paperclip$2026-04-09T00:44:15.242Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:41:52.126Z$paperclip$, $paperclip$2026-04-09T00:44:23.939Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:42:00.188Z$paperclip$, $paperclip$2026-04-09T00:44:31.530Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:42:08.263Z$paperclip$, $paperclip$2026-04-09T00:44:40.004Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T22:07:35.367Z$paperclip$, $paperclip$2026-04-09T00:50:19.185Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:57:02.183Z$paperclip$, $paperclip$2026-04-09T01:01:17.798Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:57:14.274Z$paperclip$, $paperclip$2026-04-09T01:01:25.952Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:57:26.347Z$paperclip$, $paperclip$2026-04-09T01:01:39.616Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:57:38.421Z$paperclip$, $paperclip$2026-04-09T01:01:50.406Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.155Z$paperclip$, $paperclip$2026-04-08T23:42:29.754Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.351Z$paperclip$, $paperclip$2026-04-08T23:50:06.212Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T23:27:28.211Z$paperclip$, $paperclip$2026-04-08T23:50:07.974Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.125Z$paperclip$, $paperclip$2026-04-09T00:01:36.466Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:20:29.252Z$paperclip$, $paperclip$2026-04-09T00:20:40.918Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:20:41.349Z$paperclip$, $paperclip$2026-04-09T00:21:21.435Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:21:21.604Z$paperclip$, $paperclip$2026-04-09T00:22:06.285Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:22:07.819Z$paperclip$, $paperclip$2026-04-09T00:22:15.710Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$e486e9c1-7fb6-4671-b1db-3f0d66c19121$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, NULL, NULL, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:40:40.158Z$paperclip$, $paperclip$2026-04-09T00:40:40.158Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_runtime_state" ("agent_id", "company_id", "adapter_type", "session_id", "state_json", "last_run_id", "last_run_status", "total_input_tokens", "total_output_tokens", "total_cached_input_tokens", "total_cost_cents", "last_error", "created_at", "updated_at") VALUES ($paperclip$265c953e-789f-41d2-a483-20c71c0430bf$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$process$paperclip$, NULL, $paperclip${}$paperclip$, NULL, NULL, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, $paperclip$0$paperclip$, NULL, $paperclip$2026-04-09T00:40:45.525Z$paperclip$, $paperclip$2026-04-09T00:40:45.525Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agent_wakeup_requests (73 rows)
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
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$91b84942-eeed-454c-914d-7a1ef1e882cd$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$coalesced$paperclip$, 1, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$2026-04-08T23:15:37.315Z$paperclip$, NULL, $paperclip$2026-04-08T23:15:37.315Z$paperclip$, NULL, $paperclip$2026-04-08T23:15:37.315Z$paperclip$, $paperclip$2026-04-08T23:15:37.315Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$3a138a6d-c9cc-461e-b8af-bbf7550a22e6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$coalesced$paperclip$, 1, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$2026-04-08T23:16:07.329Z$paperclip$, NULL, $paperclip$2026-04-08T23:16:07.328Z$paperclip$, NULL, $paperclip$2026-04-08T23:16:07.329Z$paperclip$, $paperclip$2026-04-08T23:16:07.329Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$b04530ae-9844-4261-9a95-0089820f4a63$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, $paperclip$2026-04-08T23:27:26.174Z$paperclip$, $paperclip$2026-04-08T23:27:26.180Z$paperclip$, $paperclip$2026-04-08T23:27:27.327Z$paperclip$, NULL, $paperclip$2026-04-08T23:27:26.174Z$paperclip$, $paperclip$2026-04-08T23:27:27.327Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$f45fc661-88e8-449f-add2-45211bcb8f31$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$coalesced$paperclip$, 1, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$2026-04-08T23:16:37.318Z$paperclip$, NULL, $paperclip$2026-04-08T23:16:37.318Z$paperclip$, NULL, $paperclip$2026-04-08T23:16:37.318Z$paperclip$, $paperclip$2026-04-08T23:16:37.318Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$26930d77-3cec-48a0-af5e-053a51e79efa$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$coalesced$paperclip$, 1, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$2026-04-08T23:17:07.322Z$paperclip$, NULL, $paperclip$2026-04-08T23:17:07.322Z$paperclip$, NULL, $paperclip$2026-04-08T23:17:07.322Z$paperclip$, $paperclip$2026-04-08T23:17:07.322Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$4db66a0d-7f5f-4058-b8fd-7fe1c11a800f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$failed$paperclip$, 0, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$2026-04-08T23:15:07.312Z$paperclip$, $paperclip$2026-04-08T23:15:07.321Z$paperclip$, $paperclip$2026-04-08T23:17:36.601Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T23:15:07.312Z$paperclip$, $paperclip$2026-04-08T23:17:36.601Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$7524e461-c52f-405a-8ac2-9bcbc9c3d0d5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, $paperclip$2026-04-08T23:37:05.975Z$paperclip$, $paperclip$2026-04-08T23:37:05.982Z$paperclip$, $paperclip$2026-04-08T23:37:16.410Z$paperclip$, NULL, $paperclip$2026-04-08T23:37:05.975Z$paperclip$, $paperclip$2026-04-08T23:37:16.410Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$cb2d6c8f-bac7-43b7-953e-c3ef4cf0b566$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, $paperclip$2026-04-08T23:27:14.101Z$paperclip$, $paperclip$2026-04-08T23:27:14.107Z$paperclip$, $paperclip$2026-04-08T23:27:24.738Z$paperclip$, NULL, $paperclip$2026-04-08T23:27:14.101Z$paperclip$, $paperclip$2026-04-08T23:27:24.738Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$2765cf7e-d4c0-49a0-b3e6-5a1f864547f5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, $paperclip$2026-04-08T23:37:18.037Z$paperclip$, $paperclip$2026-04-08T23:37:18.044Z$paperclip$, $paperclip$2026-04-08T23:37:19.309Z$paperclip$, NULL, $paperclip$2026-04-08T23:37:18.037Z$paperclip$, $paperclip$2026-04-08T23:37:19.309Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$ca0f7ce3-5f4d-474b-8479-67c78f2bc8b6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, $paperclip$2026-04-08T23:27:28.202Z$paperclip$, $paperclip$2026-04-08T23:27:28.208Z$paperclip$, $paperclip$2026-04-08T23:27:29.173Z$paperclip$, NULL, $paperclip$2026-04-08T23:27:28.202Z$paperclip$, $paperclip$2026-04-08T23:27:29.173Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$be7d4bdc-efc7-4231-83c2-19ae83acd050$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, $paperclip$2026-04-08T23:27:48.759Z$paperclip$, $paperclip$2026-04-08T23:27:48.762Z$paperclip$, $paperclip$2026-04-08T23:27:48.811Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T23:27:48.759Z$paperclip$, $paperclip$2026-04-08T23:27:48.811Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$fa074f4a-5a10-45c1-8173-2a95ec655b23$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, $paperclip$2026-04-08T23:37:20.064Z$paperclip$, $paperclip$2026-04-08T23:37:20.070Z$paperclip$, $paperclip$2026-04-08T23:37:21.153Z$paperclip$, NULL, $paperclip$2026-04-08T23:37:20.064Z$paperclip$, $paperclip$2026-04-08T23:37:21.153Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$0a429d30-48c1-4b0b-a139-cae0c31351b5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$assignment$paperclip$, $paperclip$system$paperclip$, $paperclip$issue_assigned$paperclip$, $paperclip${"issueId":"6e292396-541e-424d-b5a7-229ea9408ad2","mutation":"create"}$paperclip$, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$5d94a597-3530-46ac-90d5-6ae8a3333b70$paperclip$, $paperclip$2026-04-08T23:42:07.129Z$paperclip$, $paperclip$2026-04-08T23:42:07.148Z$paperclip$, $paperclip$2026-04-08T23:42:19.180Z$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.129Z$paperclip$, $paperclip$2026-04-08T23:42:19.180Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$dfacf0a5-0aa0-4c11-888e-d0f9ab042f49$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, $paperclip$2026-04-08T23:27:50.799Z$paperclip$, $paperclip$2026-04-08T23:27:50.804Z$paperclip$, $paperclip$2026-04-08T23:27:51.673Z$paperclip$, NULL, $paperclip$2026-04-08T23:27:50.799Z$paperclip$, $paperclip$2026-04-08T23:27:51.673Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$785c0b19-c5ea-4216-bd3c-23ce0caefeb0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, $paperclip$2026-04-08T23:34:06.940Z$paperclip$, $paperclip$2026-04-08T23:34:06.944Z$paperclip$, $paperclip$2026-04-08T23:34:15.005Z$paperclip$, NULL, $paperclip$2026-04-08T23:34:06.940Z$paperclip$, $paperclip$2026-04-08T23:34:15.005Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$08ffe34b-c1fa-4f6a-b973-ffc555cb8d3f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, $paperclip$2026-04-08T23:34:16.991Z$paperclip$, $paperclip$2026-04-08T23:34:16.999Z$paperclip$, $paperclip$2026-04-08T23:34:18.165Z$paperclip$, NULL, $paperclip$2026-04-08T23:34:16.991Z$paperclip$, $paperclip$2026-04-08T23:34:18.165Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$0f5b58ef-2f23-429f-beb9-ad9399340206$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$assignment$paperclip$, $paperclip$system$paperclip$, $paperclip$issue_assigned$paperclip$, $paperclip${"issueId":"ae527462-ab1e-4362-a62d-28ae885a0563","mutation":"create"}$paperclip$, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$18f1f4b3-b4dc-47ee-8c68-ee2425d025ff$paperclip$, $paperclip$2026-04-08T23:42:07.106Z$paperclip$, $paperclip$2026-04-08T23:42:07.112Z$paperclip$, $paperclip$2026-04-08T23:42:17.979Z$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.106Z$paperclip$, $paperclip$2026-04-08T23:42:17.979Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$67803413-0648-49e8-81d7-fa8d5fadbd73$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, $paperclip$2026-04-08T23:34:19.028Z$paperclip$, $paperclip$2026-04-08T23:34:19.037Z$paperclip$, $paperclip$2026-04-08T23:34:20.010Z$paperclip$, NULL, $paperclip$2026-04-08T23:34:19.028Z$paperclip$, $paperclip$2026-04-08T23:34:20.010Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$71031a29-6b33-43f3-9e90-0571f7e37dae$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$2026-04-08T23:42:07.145Z$paperclip$, $paperclip$2026-04-08T23:42:19.307Z$paperclip$, $paperclip$2026-04-08T23:42:29.751Z$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.145Z$paperclip$, $paperclip$2026-04-08T23:42:29.751Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$5c37f3a5-b148-40c3-88ad-aee7da8bec6a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$automation$paperclip$, $paperclip$system$paperclip$, $paperclip$issue_execution_promoted$paperclip$, $paperclip${"issueId":"ae527462-ab1e-4362-a62d-28ae885a0563","mutation":"comment","commentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","_paperclipWakeContext":{"source":"issue.comment","taskId":"ae527462-ab1e-4362-a62d-28ae885a0563","issueId":"ae527462-ab1e-4362-a62d-28ae885a0563","taskKey":"ae527462-ab1e-4362-a62d-28ae885a0563","commentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","wakeReason":"issue_commented","wakeSource":"automation","wakeCommentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","wakeTriggerDetail":"system"}}$paperclip$, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$14a69919-d775-4da7-ba60-57804dd1da4f$paperclip$, $paperclip$2026-04-08T23:42:07.145Z$paperclip$, $paperclip$2026-04-08T23:42:17.989Z$paperclip$, $paperclip$2026-04-08T23:42:37.127Z$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.145Z$paperclip$, $paperclip$2026-04-08T23:42:37.127Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$7edeb15d-04d7-4627-bedd-3108e53b1b39$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, $paperclip$2026-04-08T23:45:15.599Z$paperclip$, $paperclip$2026-04-08T23:45:15.603Z$paperclip$, $paperclip$2026-04-08T23:45:29.124Z$paperclip$, NULL, $paperclip$2026-04-08T23:45:15.599Z$paperclip$, $paperclip$2026-04-08T23:45:29.124Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$8195a8df-f075-41c6-999d-9ad7c9e5cd53$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, $paperclip$2026-04-08T23:45:29.690Z$paperclip$, $paperclip$2026-04-08T23:45:29.694Z$paperclip$, $paperclip$2026-04-08T23:45:31.114Z$paperclip$, NULL, $paperclip$2026-04-08T23:45:29.690Z$paperclip$, $paperclip$2026-04-08T23:45:31.114Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$5f5da724-852b-4b61-be2b-506174725e91$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, $paperclip$2026-04-08T23:47:27.130Z$paperclip$, $paperclip$2026-04-08T23:47:27.138Z$paperclip$, $paperclip$2026-04-08T23:47:28.262Z$paperclip$, NULL, $paperclip$2026-04-08T23:47:27.130Z$paperclip$, $paperclip$2026-04-08T23:47:28.262Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$2f9ad684-7897-420b-aea9-7c6c10cd6cfc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, $paperclip$2026-04-08T23:45:31.719Z$paperclip$, $paperclip$2026-04-08T23:45:31.727Z$paperclip$, $paperclip$2026-04-08T23:45:32.767Z$paperclip$, NULL, $paperclip$2026-04-08T23:45:31.719Z$paperclip$, $paperclip$2026-04-08T23:45:32.767Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$3351a392-624a-412f-9476-209acf7f2bf4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, $paperclip$2026-04-08T23:47:13.044Z$paperclip$, $paperclip$2026-04-08T23:47:13.047Z$paperclip$, $paperclip$2026-04-08T23:47:24.631Z$paperclip$, NULL, $paperclip$2026-04-08T23:47:13.044Z$paperclip$, $paperclip$2026-04-08T23:47:24.632Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$35587f71-17d3-40f0-94fb-46644c059634$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, $paperclip$2026-04-08T23:47:25.101Z$paperclip$, $paperclip$2026-04-08T23:47:25.107Z$paperclip$, $paperclip$2026-04-08T23:47:26.445Z$paperclip$, NULL, $paperclip$2026-04-08T23:47:25.101Z$paperclip$, $paperclip$2026-04-08T23:47:26.445Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$8ed4e084-fad9-444e-8b6e-d367a584a833$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, $paperclip$2026-04-08T23:49:25.801Z$paperclip$, $paperclip$2026-04-08T23:49:25.805Z$paperclip$, $paperclip$2026-04-08T23:49:36.322Z$paperclip$, NULL, $paperclip$2026-04-08T23:49:25.801Z$paperclip$, $paperclip$2026-04-08T23:49:36.322Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$c743342f-b99c-4cae-aea9-5f35739817b9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, $paperclip$2026-04-08T23:49:54.932Z$paperclip$, $paperclip$2026-04-08T23:49:54.935Z$paperclip$, $paperclip$2026-04-08T23:50:04.629Z$paperclip$, NULL, $paperclip$2026-04-08T23:49:54.932Z$paperclip$, $paperclip$2026-04-08T23:50:04.629Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$50a2af8f-5633-4bd7-a46c-c46576214069$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$failed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, $paperclip$2026-04-08T23:49:37.864Z$paperclip$, $paperclip$2026-04-08T23:49:37.870Z$paperclip$, $paperclip$2026-04-08T23:49:38.251Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, $paperclip$2026-04-08T23:49:37.864Z$paperclip$, $paperclip$2026-04-08T23:49:38.251Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$68401fa6-7167-48de-b7cb-c3384a081b23$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$2026-04-08T23:50:05.008Z$paperclip$, $paperclip$2026-04-08T23:50:05.013Z$paperclip$, $paperclip$2026-04-08T23:50:06.209Z$paperclip$, NULL, $paperclip$2026-04-08T23:50:05.008Z$paperclip$, $paperclip$2026-04-08T23:50:06.209Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$49b14019-ca3d-4057-b829-0af1da74de0c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$2026-04-08T23:50:07.039Z$paperclip$, $paperclip$2026-04-08T23:50:07.045Z$paperclip$, $paperclip$2026-04-08T23:50:07.970Z$paperclip$, NULL, $paperclip$2026-04-08T23:50:07.039Z$paperclip$, $paperclip$2026-04-08T23:50:07.970Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$2a6aea40-3363-446a-862b-820f14be8b3f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, $paperclip$2026-04-08T23:57:13.436Z$paperclip$, $paperclip$2026-04-08T23:57:13.442Z$paperclip$, $paperclip$2026-04-08T23:57:23.972Z$paperclip$, NULL, $paperclip$2026-04-08T23:57:13.436Z$paperclip$, $paperclip$2026-04-08T23:57:23.972Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$f29dc5fc-be80-4887-a202-f63ad22d1908$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$2026-04-09T00:01:27.444Z$paperclip$, $paperclip$2026-04-09T00:01:27.449Z$paperclip$, $paperclip$2026-04-09T00:01:36.463Z$paperclip$, NULL, $paperclip$2026-04-09T00:01:27.444Z$paperclip$, $paperclip$2026-04-09T00:01:36.463Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$6b22e088-f1c8-41a6-83c7-bfa3544cfdd0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, $paperclip$2026-04-08T23:59:52.798Z$paperclip$, $paperclip$2026-04-08T23:59:52.801Z$paperclip$, $paperclip$2026-04-09T00:00:03.160Z$paperclip$, NULL, $paperclip$2026-04-08T23:59:52.798Z$paperclip$, $paperclip$2026-04-09T00:00:03.160Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$6d45a7a0-e4ad-4fef-9957-88126e841f3c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$2026-04-09T00:20:29.245Z$paperclip$, $paperclip$2026-04-09T00:20:29.250Z$paperclip$, $paperclip$2026-04-09T00:20:40.913Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:29.245Z$paperclip$, $paperclip$2026-04-09T00:20:40.913Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$ba441868-5831-4407-af46-a1352fbc3d36$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$2026-04-09T00:20:41.338Z$paperclip$, $paperclip$2026-04-09T00:20:41.346Z$paperclip$, $paperclip$2026-04-09T00:21:21.432Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:41.338Z$paperclip$, $paperclip$2026-04-09T00:21:21.432Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$969bc9c4-a14c-4d81-a364-dc76a673976d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$2026-04-09T00:21:21.596Z$paperclip$, $paperclip$2026-04-09T00:21:21.601Z$paperclip$, $paperclip$2026-04-09T00:22:06.281Z$paperclip$, NULL, $paperclip$2026-04-09T00:21:21.596Z$paperclip$, $paperclip$2026-04-09T00:22:06.281Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$7b6deaf7-5a55-4da0-b0cc-a66000d983db$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$2026-04-09T00:22:07.809Z$paperclip$, $paperclip$2026-04-09T00:22:07.816Z$paperclip$, $paperclip$2026-04-09T00:22:15.708Z$paperclip$, NULL, $paperclip$2026-04-09T00:22:07.809Z$paperclip$, $paperclip$2026-04-09T00:22:15.708Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$b0cbadcd-7e84-453d-82fc-e23408ca41fb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$2026-04-09T00:44:04.311Z$paperclip$, $paperclip$2026-04-09T00:44:04.315Z$paperclip$, $paperclip$2026-04-09T00:44:15.239Z$paperclip$, NULL, $paperclip$2026-04-09T00:44:04.311Z$paperclip$, $paperclip$2026-04-09T00:44:15.239Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$60792975-a9fe-4e3e-a595-725a800e109c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, $paperclip$2026-04-09T00:41:42.052Z$paperclip$, $paperclip$2026-04-09T00:41:42.056Z$paperclip$, $paperclip$2026-04-09T00:41:50.402Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.052Z$paperclip$, $paperclip$2026-04-09T00:41:50.402Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$6531a7f8-cb4b-42d4-88ec-997fb9fee340$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$2026-04-09T00:44:16.374Z$paperclip$, $paperclip$2026-04-09T00:44:16.382Z$paperclip$, $paperclip$2026-04-09T00:44:23.936Z$paperclip$, NULL, $paperclip$2026-04-09T00:44:16.374Z$paperclip$, $paperclip$2026-04-09T00:44:23.936Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$5c157ca7-8701-4fbf-b4ac-32ba1570d933$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, $paperclip$2026-04-09T00:41:52.115Z$paperclip$, $paperclip$2026-04-09T00:41:52.122Z$paperclip$, $paperclip$2026-04-09T00:41:59.655Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:52.115Z$paperclip$, $paperclip$2026-04-09T00:41:59.655Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$050545b2-4cd5-416f-9a89-ce660bb77b2b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$2026-04-09T00:44:24.434Z$paperclip$, $paperclip$2026-04-09T00:44:24.442Z$paperclip$, $paperclip$2026-04-09T00:44:31.527Z$paperclip$, NULL, $paperclip$2026-04-09T00:44:24.434Z$paperclip$, $paperclip$2026-04-09T00:44:31.527Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$649a413c-386f-4238-b559-4f35920636b9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, $paperclip$2026-04-09T00:42:00.174Z$paperclip$, $paperclip$2026-04-09T00:42:00.183Z$paperclip$, $paperclip$2026-04-09T00:42:07.740Z$paperclip$, NULL, $paperclip$2026-04-09T00:42:00.174Z$paperclip$, $paperclip$2026-04-09T00:42:07.740Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$dcfead73-fac9-4126-9f0b-2b5c8d9a8fc8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$2026-04-09T00:44:32.494Z$paperclip$, $paperclip$2026-04-09T00:44:32.501Z$paperclip$, $paperclip$2026-04-09T00:44:40.001Z$paperclip$, NULL, $paperclip$2026-04-09T00:44:32.494Z$paperclip$, $paperclip$2026-04-09T00:44:40.001Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$be475d78-28bc-4dd8-b7e3-7a02a0a17363$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, $paperclip$2026-04-09T00:42:08.250Z$paperclip$, $paperclip$2026-04-09T00:42:08.257Z$paperclip$, $paperclip$2026-04-09T00:42:15.464Z$paperclip$, NULL, $paperclip$2026-04-09T00:42:08.250Z$paperclip$, $paperclip$2026-04-09T00:42:15.464Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$85166446-6e10-4d6c-9a36-3b9ba8b1d33f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$system$paperclip$, $paperclip$heartbeat_timer$paperclip$, NULL, $paperclip$completed$paperclip$, 0, $paperclip$system$paperclip$, $paperclip$heartbeat_scheduler$paperclip$, NULL, $paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$2026-04-09T00:50:07.590Z$paperclip$, $paperclip$2026-04-09T00:50:07.601Z$paperclip$, $paperclip$2026-04-09T00:50:19.182Z$paperclip$, NULL, $paperclip$2026-04-09T00:50:07.590Z$paperclip$, $paperclip$2026-04-09T00:50:19.182Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$8fe7c72d-1cef-49e2-9354-b2b7f84a42d5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, $paperclip$2026-04-09T00:58:46.227Z$paperclip$, $paperclip$2026-04-09T00:58:46.231Z$paperclip$, $paperclip$2026-04-09T00:58:57.303Z$paperclip$, NULL, $paperclip$2026-04-09T00:58:46.227Z$paperclip$, $paperclip$2026-04-09T00:58:57.303Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$5ad9dbc1-b4d0-481b-81b6-1877e65adc77$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, $paperclip$2026-04-09T00:57:02.164Z$paperclip$, $paperclip$2026-04-09T00:57:02.174Z$paperclip$, $paperclip$2026-04-09T00:57:12.910Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:02.164Z$paperclip$, $paperclip$2026-04-09T00:57:12.910Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$41c3a68f-c4c0-468d-9117-efadd54c7db8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, $paperclip$2026-04-09T00:57:14.264Z$paperclip$, $paperclip$2026-04-09T00:57:14.268Z$paperclip$, $paperclip$2026-04-09T00:57:24.351Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:14.264Z$paperclip$, $paperclip$2026-04-09T00:57:24.351Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$9c4cf280-2f1b-4c7c-8dc6-0c00f57207ee$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$2026-04-09T01:01:40.315Z$paperclip$, $paperclip$2026-04-09T01:01:40.319Z$paperclip$, $paperclip$2026-04-09T01:01:50.403Z$paperclip$, NULL, $paperclip$2026-04-09T01:01:40.315Z$paperclip$, $paperclip$2026-04-09T01:01:50.403Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$f36b239a-e8ce-4cfb-b9e2-c4dcf4944edf$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, $paperclip$2026-04-09T00:57:26.338Z$paperclip$, $paperclip$2026-04-09T00:57:26.344Z$paperclip$, $paperclip$2026-04-09T00:57:36.432Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:26.338Z$paperclip$, $paperclip$2026-04-09T00:57:36.432Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$44a7aafe-9e99-4d43-95d5-126f8eabfbe6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, $paperclip$2026-04-09T00:57:38.413Z$paperclip$, $paperclip$2026-04-09T00:57:38.418Z$paperclip$, $paperclip$2026-04-09T00:57:44.783Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:38.413Z$paperclip$, $paperclip$2026-04-09T00:57:44.783Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$4a05a240-02a3-4ad8-b32e-2d075eed5b51$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, $paperclip$2026-04-09T00:58:58.292Z$paperclip$, $paperclip$2026-04-09T00:58:58.297Z$paperclip$, $paperclip$2026-04-09T00:59:05.654Z$paperclip$, NULL, $paperclip$2026-04-09T00:58:58.292Z$paperclip$, $paperclip$2026-04-09T00:59:05.654Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$95cb83b4-dc8f-420d-aebb-a0819e4417e2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, $paperclip$2026-04-09T00:58:36.083Z$paperclip$, $paperclip$2026-04-09T00:58:36.096Z$paperclip$, $paperclip$2026-04-09T00:58:44.441Z$paperclip$, NULL, $paperclip$2026-04-09T00:58:36.083Z$paperclip$, $paperclip$2026-04-09T00:58:44.441Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$4a651a2f-c7cd-4a13-afa4-6963a96a8fed$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, $paperclip$2026-04-09T00:59:06.356Z$paperclip$, $paperclip$2026-04-09T00:59:06.360Z$paperclip$, $paperclip$2026-04-09T00:59:13.626Z$paperclip$, NULL, $paperclip$2026-04-09T00:59:06.356Z$paperclip$, $paperclip$2026-04-09T00:59:13.626Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$6f4f9fca-b2fe-4b47-b78b-5d1d04dd704b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$2026-04-09T01:01:10.117Z$paperclip$, $paperclip$2026-04-09T01:01:10.120Z$paperclip$, $paperclip$2026-04-09T01:01:17.795Z$paperclip$, NULL, $paperclip$2026-04-09T01:01:10.117Z$paperclip$, $paperclip$2026-04-09T01:01:17.795Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$d00be332-2763-4faf-9e81-efb3a217c2b6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$2026-04-09T01:01:18.165Z$paperclip$, $paperclip$2026-04-09T01:01:18.169Z$paperclip$, $paperclip$2026-04-09T01:01:25.950Z$paperclip$, NULL, $paperclip$2026-04-09T01:01:18.165Z$paperclip$, $paperclip$2026-04-09T01:01:25.950Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agent_wakeup_requests" ("id", "company_id", "agent_id", "source", "trigger_detail", "reason", "payload", "status", "coalesced_count", "requested_by_actor_type", "requested_by_actor_id", "idempotency_key", "run_id", "requested_at", "claimed_at", "finished_at", "error", "created_at", "updated_at") VALUES ($paperclip$9ad5be99-0299-4e07-87e2-12225d974739$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$manual$paperclip$, NULL, NULL, $paperclip$completed$paperclip$, 0, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, NULL, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$2026-04-09T01:01:26.209Z$paperclip$, $paperclip$2026-04-09T01:01:26.213Z$paperclip$, $paperclip$2026-04-09T01:01:39.613Z$paperclip$, NULL, $paperclip$2026-04-09T01:01:26.209Z$paperclip$, $paperclip$2026-04-09T01:01:39.613Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.agents (19 rows)
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$e486e9c1-7fb6-4671-b1db-3f0d66c19121$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$DevOpsAgent$paperclip$, $paperclip$devops$paperclip$, $paperclip$DevOps Agent$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$DevOpsAgent role in P2.3 hierarchy slice$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, NULL, NULL, $paperclip$2026-04-08T23:41:48.603Z$paperclip$, $paperclip$2026-04-08T23:41:48.603Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$265c953e-789f-41d2-a483-20c71c0430bf$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$QAEngineer$paperclip$, $paperclip$qa$paperclip$, $paperclip$QA Engineer$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$QAEngineer role in P2.3 hierarchy slice$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, NULL, NULL, $paperclip$2026-04-08T23:41:48.610Z$paperclip$, $paperclip$2026-04-08T23:41:48.610Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$EngineeringBuilder$paperclip$, $paperclip$engineer$paperclip$, $paperclip$Engineering Builder$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$EngineeringBuilder role in P2.3 hierarchy slice$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-08T23:42:29.755Z$paperclip$, NULL, $paperclip$2026-04-08T23:41:48.597Z$paperclip$, $paperclip$2026-04-08T23:42:29.755Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ComplianceCounsel$paperclip$, $paperclip$general$paperclip$, $paperclip$Compliance Counsel$paperclip$, $paperclip$idle$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$Owns legal/compliance lane checks and policy execution under LegalComplianceChief.$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T01:01:25.954Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:14.251Z$paperclip$, $paperclip$2026-04-09T01:01:25.954Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$OpenClawWorker$paperclip$, $paperclip$engineer$paperclip$, $paperclip$OpenClaw Runtime Worker$paperclip$, $paperclip$idle$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$Role-dispatched planner runtime via role-routing source-of-truth$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"planner"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-08T23:50:06.214Z$paperclip$, NULL, $paperclip$2026-04-08T22:08:35.333Z$paperclip$, $paperclip$2026-04-08T23:50:06.214Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$EmbeddingWorker$paperclip$, $paperclip$engineer$paperclip$, $paperclip$Embedding Runtime Worker$paperclip$, $paperclip$idle$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$Role-dispatched embedding runtime via role-routing source-of-truth$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"embedding"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-08T23:50:07.975Z$paperclip$, NULL, $paperclip$2026-04-08T23:27:06.174Z$paperclip$, $paperclip$2026-04-08T23:50:07.975Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ChiefOfStaff$paperclip$, $paperclip$general$paperclip$, $paperclip$Chief of Staff$paperclip$, $paperclip$idle$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$ChiefOfStaff role in P2.3 hierarchy slice$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:01:36.467Z$paperclip$, NULL, $paperclip$2026-04-08T23:41:48.585Z$paperclip$, $paperclip$2026-04-09T00:01:36.467Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ReviewScriptAuditor$paperclip$, $paperclip$qa$paperclip$, $paperclip$Script Auditor Reviewer$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$ReviewScriptAuditor reviewer skeleton for P2.7$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:20:40.919Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:03.188Z$paperclip$, $paperclip$2026-04-09T00:20:40.919Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ReviewCostInfra$paperclip$, $paperclip$devops$paperclip$, $paperclip$Cost Infra Reviewer$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$ReviewCostInfra reviewer skeleton for P2.7$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:21:21.437Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:03.199Z$paperclip$, $paperclip$2026-04-09T00:21:21.437Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ReviewLicense$paperclip$, $paperclip$general$paperclip$, $paperclip$License Reviewer$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$ReviewLicense reviewer skeleton for P2.7$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:22:06.286Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:03.204Z$paperclip$, $paperclip$2026-04-09T00:22:06.286Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ReviewPhaseBoundary$paperclip$, $paperclip$pm$paperclip$, $paperclip$Phase Boundary Reviewer$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$ReviewPhaseBoundary reviewer skeleton for P2.7$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:22:15.711Z$paperclip$, NULL, $paperclip$2026-04-09T00:20:03.209Z$paperclip$, $paperclip$2026-04-09T00:22:15.711Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$LegalComplianceChief$paperclip$, $paperclip$general$paperclip$, $paperclip$Legal Compliance Chief$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$LegalComplianceChief chief role for P2.3 wave2$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:44:23.940Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.040Z$paperclip$, $paperclip$2026-04-09T00:44:23.940Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$CEO$paperclip$, $paperclip$ceo$paperclip$, NULL, $paperclip$idle$paperclip$, NULL, $paperclip$OpenClaw gateway-backed execution (RunPod-backed via Foreman config)$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","graceSec":15,"timeoutSec":240,"instructionsFilePath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions/AGENTS.md","instructionsRootPath":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/companies/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/agents/b82a9601-f0c3-41b5-9a15-571d868b6b1e/instructions","instructionsEntryFile":"AGENTS.md","instructionsBundleMode":"managed"}$paperclip$, 0, 0, $paperclip$2026-04-09T00:50:19.186Z$paperclip$, NULL, $paperclip$2026-04-08T22:07:24.514Z$paperclip$, $paperclip$2026-04-09T00:50:19.186Z$paperclip$, $paperclip${"heartbeat":{"enabled":true,"cooldownSec":10,"intervalSec":3600,"wakeOnDemand":true,"maxConcurrentRuns":1}}$paperclip$, $paperclip${"canCreateAgents":true}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$FinanceChief$paperclip$, $paperclip$cfo$paperclip$, $paperclip$Finance Chief$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$FinanceChief chief role for P2.3 wave2$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:44:31.530Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.044Z$paperclip$, $paperclip$2026-04-09T00:44:31.530Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$GrowthChief$paperclip$, $paperclip$cmo$paperclip$, $paperclip$Growth Chief$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$GrowthChief chief role for P2.3 wave2$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:44:40.005Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.047Z$paperclip$, $paperclip$2026-04-09T00:44:40.005Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$DemandGenLead$paperclip$, $paperclip$cmo$paperclip$, $paperclip$Demand Generation Lead$paperclip$, $paperclip$idle$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$Owns growth lane demand-gen execution under GrowthChief.$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T01:01:50.407Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:38.400Z$paperclip$, $paperclip$2026-04-09T01:01:50.407Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$BudgetAnalyst$paperclip$, $paperclip$cfo$paperclip$, $paperclip$Budget Analyst$paperclip$, $paperclip$idle$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$Owns finance lane budgeting/forecast execution under FinanceChief.$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T01:01:39.617Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:26.330Z$paperclip$, $paperclip$2026-04-09T01:01:39.617Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ProductLeadChief$paperclip$, $paperclip$pm$paperclip$, $paperclip$Product Lead Chief$paperclip$, $paperclip$idle$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$ProductLeadChief chief role for P2.3 wave2$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T00:44:15.243Z$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.036Z$paperclip$, $paperclip$2026-04-09T00:44:15.243Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."agents" ("id", "company_id", "name", "role", "title", "status", "reports_to", "capabilities", "adapter_type", "adapter_config", "budget_monthly_cents", "spent_monthly_cents", "last_heartbeat_at", "metadata", "created_at", "updated_at", "runtime_config", "permissions", "icon", "pause_reason", "paused_at") VALUES ($paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ProductAnalyst$paperclip$, $paperclip$pm$paperclip$, $paperclip$Product Analyst$paperclip$, $paperclip$idle$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$Owns product lane analysis and execution support under ProductLeadChief.$paperclip$, $paperclip$process$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"PAPERCLIP_ROLE":{"type":"plain","value":"executor"}},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","timeoutSec":180}$paperclip$, 0, 0, $paperclip$2026-04-09T01:01:17.799Z$paperclip$, NULL, $paperclip$2026-04-09T00:57:02.151Z$paperclip$, $paperclip$2026-04-09T01:01:17.799Z$paperclip$, $paperclip${}$paperclip$, $paperclip${"canCreateAgents":false}$paperclip$, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.companies (2 rows)
INSERT INTO "public"."companies" ("id", "name", "description", "status", "budget_monthly_cents", "spent_monthly_cents", "created_at", "updated_at", "issue_prefix", "issue_counter", "require_board_approval_for_new_agents", "brand_color", "pause_reason", "paused_at", "feedback_data_sharing_enabled", "feedback_data_sharing_consent_at", "feedback_data_sharing_consent_by_user_id", "feedback_data_sharing_terms_version") VALUES ($paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$Foreman$paperclip$, NULL, $paperclip$active$paperclip$, 0, 0, $paperclip$2026-04-08T22:06:20.123Z$paperclip$, $paperclip$2026-04-08T22:06:20.123Z$paperclip$, $paperclip$FOR$paperclip$, 11, true, NULL, NULL, NULL, false, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."companies" ("id", "name", "description", "status", "budget_monthly_cents", "spent_monthly_cents", "created_at", "updated_at", "issue_prefix", "issue_counter", "require_board_approval_for_new_agents", "brand_color", "pause_reason", "paused_at", "feedback_data_sharing_enabled", "feedback_data_sharing_consent_at", "feedback_data_sharing_consent_by_user_id", "feedback_data_sharing_terms_version") VALUES ($paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$Foreman-Isolation-B$paperclip$, NULL, $paperclip$active$paperclip$, 0, 0, $paperclip$2026-04-09T00:06:05.028Z$paperclip$, $paperclip$2026-04-09T00:06:05.028Z$paperclip$, $paperclip$FORA$paperclip$, 7, true, NULL, NULL, NULL, false, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.company_memberships (21 rows)
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$db303805-43c5-4486-ab3d-2a36d8f8e08c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$active$paperclip$, $paperclip$owner$paperclip$, $paperclip$2026-04-08T22:06:20.133Z$paperclip$, $paperclip$2026-04-08T22:06:20.133Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$a3c3d76e-db00-4ddf-be65-049ebc224664$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T22:07:24.529Z$paperclip$, $paperclip$2026-04-08T22:07:24.529Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$6d2f77a5-b369-4738-94c0-b77f31345487$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T22:08:35.335Z$paperclip$, $paperclip$2026-04-08T22:08:35.335Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$86297086-e284-4ea6-953a-49f1c96dd699$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T23:27:06.180Z$paperclip$, $paperclip$2026-04-08T23:27:06.180Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$d6ed1429-fc59-402b-922c-78b2a8b19e81$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T23:41:48.592Z$paperclip$, $paperclip$2026-04-08T23:41:48.592Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$f360bcec-e40d-4001-99fb-873f118cbbd3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T23:41:48.599Z$paperclip$, $paperclip$2026-04-08T23:41:48.599Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$2fb98fd1-09c0-4c34-8982-b354f00eba3e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$e486e9c1-7fb6-4671-b1db-3f0d66c19121$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T23:41:48.606Z$paperclip$, $paperclip$2026-04-08T23:41:48.606Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$b9faa97b-3e5f-4931-8c7c-47eea434d9a1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$265c953e-789f-41d2-a483-20c71c0430bf$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-08T23:41:48.613Z$paperclip$, $paperclip$2026-04-08T23:41:48.613Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$28479ece-8b9f-4a27-9044-41e7f4227065$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, $paperclip$user$paperclip$, $paperclip$local-board$paperclip$, $paperclip$active$paperclip$, $paperclip$owner$paperclip$, $paperclip$2026-04-09T00:06:05.033Z$paperclip$, $paperclip$2026-04-09T00:06:05.033Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$0921e1f2-018a-439e-91e0-746bc028814f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:20:03.191Z$paperclip$, $paperclip$2026-04-09T00:20:03.191Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$541094d1-2134-464c-a9f3-9c72bc81a069$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:20:03.201Z$paperclip$, $paperclip$2026-04-09T00:20:03.201Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$35be170a-5dce-4965-814f-44569840982a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:20:03.206Z$paperclip$, $paperclip$2026-04-09T00:20:03.206Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$79fc492f-9424-478d-bf5a-212fbd69f670$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:20:03.211Z$paperclip$, $paperclip$2026-04-09T00:20:03.211Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$d6ca5c50-3667-4b14-9465-36bd0ca18690$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:41:42.038Z$paperclip$, $paperclip$2026-04-09T00:41:42.038Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$6f41a195-f2bc-43d5-8734-6e24d87cb4f8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:41:42.042Z$paperclip$, $paperclip$2026-04-09T00:41:42.042Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$750b4de8-cb90-417f-8e81-bbb1ab751cc3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:41:42.045Z$paperclip$, $paperclip$2026-04-09T00:41:42.045Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$d91bc66d-57ae-4ef9-b888-2f25414368a4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:41:42.048Z$paperclip$, $paperclip$2026-04-09T00:41:42.048Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$709c59c2-088f-4ba7-9ebe-1cd894d31d16$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:57:02.154Z$paperclip$, $paperclip$2026-04-09T00:57:02.154Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$1f592381-03ad-4a79-aa29-3bf3dbc7c08a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:57:14.256Z$paperclip$, $paperclip$2026-04-09T00:57:14.256Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$a37927be-2ea6-47b1-9639-689f3ff947e5$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:57:26.332Z$paperclip$, $paperclip$2026-04-09T00:57:26.332Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."company_memberships" ("id", "company_id", "principal_type", "principal_id", "status", "membership_role", "created_at", "updated_at") VALUES ($paperclip$60ba35e1-a3f9-4125-b131-43166d3df80b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$active$paperclip$, $paperclip$member$paperclip$, $paperclip$2026-04-09T00:57:38.406Z$paperclip$, $paperclip$2026-04-09T00:57:38.406Z$paperclip$);
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
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip-create-agent$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/api-reference.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip-create-agent","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.391Z$paperclip$, $paperclip$2026-04-09T01:01:40.325Z$paperclip$);
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
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip-create-plugin$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip-create-plugin","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.408Z$paperclip$, $paperclip$2026-04-09T01:01:40.326Z$paperclip$);
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
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/para-memory-files$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/schemas.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/para-memory-files","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.417Z$paperclip$, $paperclip$2026-04-09T01:01:40.327Z$paperclip$);
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
$paperclip$, $paperclip$local_path$paperclip$, $paperclip$/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/@paperclipai/server/skills/paperclip$paperclip$, NULL, $paperclip$markdown_only$paperclip$, $paperclip$compatible$paperclip$, $paperclip$[{"kind":"reference","path":"references/api-reference.md"},{"kind":"reference","path":"references/company-skills.md"},{"kind":"reference","path":"references/routines.md"},{"kind":"skill","path":"SKILL.md"}]$paperclip$, $paperclip${"skillKey":"paperclipai/paperclip/paperclip","sourceKind":"paperclip_bundled"}$paperclip$, $paperclip$2026-04-08T22:07:35.381Z$paperclip$, $paperclip$2026-04-09T01:01:40.324Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.execution_workspaces (4 rows)
INSERT INTO "public"."execution_workspaces" ("id", "company_id", "project_id", "project_workspace_id", "source_issue_id", "mode", "strategy_type", "name", "status", "cwd", "repo_url", "base_ref", "branch_name", "provider_type", "provider_ref", "derived_from_execution_workspace_id", "last_used_at", "opened_at", "closed_at", "cleanup_eligible_at", "cleanup_reason", "metadata", "created_at", "updated_at") VALUES ($paperclip$1e0a60b4-b4d8-45ac-bb5d-a791505605e0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$shared_workspace$paperclip$, $paperclip$project_primary$paperclip$, $paperclip$FOR-1$paperclip$, $paperclip$active$paperclip$, $paperclip$/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default$paperclip$, NULL, NULL, NULL, $paperclip$local_fs$paperclip$, NULL, NULL, $paperclip$2026-04-08T22:07:35.426Z$paperclip$, $paperclip$2026-04-08T22:07:35.426Z$paperclip$, NULL, NULL, NULL, $paperclip${"source":"project_primary","createdByRuntime":false}$paperclip$, $paperclip$2026-04-08T22:07:35.427Z$paperclip$, $paperclip$2026-04-08T22:07:35.427Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."execution_workspaces" ("id", "company_id", "project_id", "project_workspace_id", "source_issue_id", "mode", "strategy_type", "name", "status", "cwd", "repo_url", "base_ref", "branch_name", "provider_type", "provider_ref", "derived_from_execution_workspace_id", "last_used_at", "opened_at", "closed_at", "cleanup_eligible_at", "cleanup_reason", "metadata", "created_at", "updated_at") VALUES ($paperclip$cd0efaf2-18d7-4649-8a11-fdf86ca9e7a2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, $paperclip$shared_workspace$paperclip$, $paperclip$project_primary$paperclip$, $paperclip$FOR-3$paperclip$, $paperclip$active$paperclip$, $paperclip$/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default$paperclip$, NULL, NULL, NULL, $paperclip$local_fs$paperclip$, NULL, NULL, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, NULL, NULL, NULL, $paperclip${"source":"project_primary","createdByRuntime":false}$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."execution_workspaces" ("id", "company_id", "project_id", "project_workspace_id", "source_issue_id", "mode", "strategy_type", "name", "status", "cwd", "repo_url", "base_ref", "branch_name", "provider_type", "provider_ref", "derived_from_execution_workspace_id", "last_used_at", "opened_at", "closed_at", "cleanup_eligible_at", "cleanup_reason", "metadata", "created_at", "updated_at") VALUES ($paperclip$fae829a1-eea3-4f76-a0c4-fe4d05471d22$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$6e292396-541e-424d-b5a7-229ea9408ad2$paperclip$, $paperclip$shared_workspace$paperclip$, $paperclip$project_primary$paperclip$, $paperclip$FOR-4$paperclip$, $paperclip$active$paperclip$, $paperclip$/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default$paperclip$, NULL, NULL, NULL, $paperclip$local_fs$paperclip$, NULL, NULL, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, NULL, NULL, NULL, $paperclip${"source":"project_primary","createdByRuntime":false}$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$, $paperclip$2026-04-08T23:42:07.162Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."execution_workspaces" ("id", "company_id", "project_id", "project_workspace_id", "source_issue_id", "mode", "strategy_type", "name", "status", "cwd", "repo_url", "base_ref", "branch_name", "provider_type", "provider_ref", "derived_from_execution_workspace_id", "last_used_at", "opened_at", "closed_at", "cleanup_eligible_at", "cleanup_reason", "metadata", "created_at", "updated_at") VALUES ($paperclip$970c4218-33e3-40a3-96d5-c36a97365246$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, $paperclip$shared_workspace$paperclip$, $paperclip$project_primary$paperclip$, $paperclip$FOR-3$paperclip$, $paperclip$active$paperclip$, $paperclip$/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default$paperclip$, NULL, NULL, NULL, $paperclip$local_fs$paperclip$, NULL, NULL, $paperclip$2026-04-08T23:42:18.037Z$paperclip$, $paperclip$2026-04-08T23:42:18.037Z$paperclip$, NULL, NULL, NULL, $paperclip${"source":"project_primary","createdByRuntime":false}$paperclip$, $paperclip$2026-04-08T23:42:18.037Z$paperclip$, $paperclip$2026-04-08T23:42:18.037Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.heartbeat_run_events (206 rows)
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
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$42$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:15:07.339Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$43$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-worker.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:15:07.342Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$44$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T23:17:36.602Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$45$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:27:14.119Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$46$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:27:14.121Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$47$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:27:24.739Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$48$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:27:26.194Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$49$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:27:26.197Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$50$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:27:27.329Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$51$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:27:28.221Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$52$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:27:28.223Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$53$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:27:29.175Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$54$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:27:48.770Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$55$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"invalid-role","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:27:48.772Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$56$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T23:27:48.812Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$57$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:27:50.816Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$58$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:27:50.818Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$59$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:27:51.674Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$60$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:34:06.957Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$61$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:34:06.959Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$62$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:34:15.006Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$63$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:34:17.013Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$74$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:37:19.310Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$87$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"788dfd8a-d944-4a3c-a1be-a8d30bb1dfde","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:42:19.352Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$88$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:42:29.753Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$89$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14a69919-d775-4da7-ba60-57804dd1da4f$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:42:37.129Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$90$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:45:15.615Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$102$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:47:25.121Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$64$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:34:17.016Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$65$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:34:18.166Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$66$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:34:19.054Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$68$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:34:20.011Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$71$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:37:16.411Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$76$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:37:20.096Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$78$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5d94a597-3530-46ac-90d5-6ae8a3333b70$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.181Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$80$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5d94a597-3530-46ac-90d5-6ae8a3333b70$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"788dfd8a-d944-4a3c-a1be-a8d30bb1dfde","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:42:07.189Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$83$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14a69919-d775-4da7-ba60-57804dd1da4f$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:42:18.050Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$85$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5d94a597-3530-46ac-90d5-6ae8a3333b70$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:42:19.182Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$97$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:45:31.748Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$99$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:47:13.057Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$109$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:49:25.816Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$67$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:34:19.059Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$69$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:37:05.996Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$72$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:37:18.057Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$81$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$18f1f4b3-b4dc-47ee-8c68-ee2425d025ff$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:42:07.194Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$82$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$18f1f4b3-b4dc-47ee-8c68-ee2425d025ff$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:42:17.981Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$84$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$14a69919-d775-4da7-ba60-57804dd1da4f$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:42:18.056Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$96$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:45:31.742Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$98$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:45:32.768Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$105$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:47:27.156Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$111$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:49:37.882Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$70$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:37:05.998Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$73$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:37:18.059Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$75$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:37:20.089Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$77$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:37:21.155Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$79$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$18f1f4b3-b4dc-47ee-8c68-ee2425d025ff$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:42:07.183Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$86$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:42:19.343Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$91$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:45:15.617Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$92$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:45:29.133Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$93$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:45:29.706Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$94$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:45:29.708Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$95$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:45:31.116Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$100$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:47:13.059Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$101$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:47:24.639Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$103$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:47:25.123Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$104$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:47:26.446Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$106$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:47:27.160Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$107$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:47:28.264Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$108$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:49:25.814Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$110$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:49:36.323Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$112$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:49:37.884Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$113$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$error$paperclip$, NULL, $paperclip$run failed$paperclip$, $paperclip${"status":"failed","exitCode":1}$paperclip$, $paperclip$2026-04-08T23:49:38.253Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$114$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:49:54.944Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$115$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:49:54.946Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$116$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:50:04.630Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$117$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:50:05.028Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$118$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"planner","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"94183066-a375-4870-be76-062cc80f34ce","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:50:05.030Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$119$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:50:06.210Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$120$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:50:07.059Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$121$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"embedding","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"865d128d-1e01-4daa-b571-f61b81d31097","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:50:07.061Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$122$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:50:07.972Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$123$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:57:13.479Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$124$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:57:13.484Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$125$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-08T23:57:23.974Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$126$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-08T23:59:52.811Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$127$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-08T23:59:52.812Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$128$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:00:03.164Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$129$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:01:27.468Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$130$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:01:27.473Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$131$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:01:36.465Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$132$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:20:29.272Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$133$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"c3c73efe-163e-4e63-9fd0-1286b4abf4cb","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:20:29.278Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$134$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:20:40.916Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$135$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:20:41.361Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$174$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:57:14.288Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$179$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:57:36.433Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$204$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T01:01:40.330Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$136$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"442238da-cff2-4ac3-b9b9-d5de8c66f1fc","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:20:41.363Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$137$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:21:21.433Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$138$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:21:21.640Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$139$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"741f87c4-b981-4c85-8e3b-1ca97ff20df8","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:21:21.644Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$140$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:22:06.283Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$141$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:22:07.832Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$142$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"4cfa9f9c-5211-4182-a630-f389ed61a3f4","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:22:07.834Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$143$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:22:15.709Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$144$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:41:42.072Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$145$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"7a2913ec-480f-40a2-920a-a047bc578025","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:41:42.081Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$146$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:41:50.404Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$147$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:41:52.136Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$149$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:41:59.656Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$154$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"837263a1-004a-4baa-b7ad-3d6b6a63a464","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:42:08.298Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$158$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:44:15.240Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$159$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:44:16.397Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$160$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:44:16.400Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$162$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:44:24.456Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$164$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:44:31.529Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$165$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:44:32.514Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$169$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"b82a9601-f0c3-41b5-9a15-571d868b6b1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:50:07.641Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$172$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2d7912a1-d0be-41af-8c2c-d7786a761494","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:57:02.266Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$148$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:41:52.139Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$150$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:42:00.208Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$151$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"58be556b-c711-47a6-8339-a8df890bb083","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:42:00.215Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$152$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:42:07.742Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$153$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:42:08.294Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$155$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:42:15.466Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$156$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:44:04.327Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$157$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"7a2913ec-480f-40a2-920a-a047bc578025","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:44:04.333Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$161$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:44:23.938Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$166$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"837263a1-004a-4baa-b7ad-3d6b6a63a464","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:44:32.517Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$167$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:44:40.003Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$168$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:50:07.626Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$170$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:50:19.183Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$171$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:57:02.255Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$176$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:57:24.358Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$182$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:57:44.784Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$163$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"58be556b-c711-47a6-8339-a8df890bb083","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:44:24.463Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$173$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:57:12.911Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$175$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:57:14.299Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$177$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:57:26.357Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$178$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"fc538926-ae82-4271-942d-079132c27cbc","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:57:26.362Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$180$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:57:38.450Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$181$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"921a8222-e657-4233-9cf4-c7c9ccb98eb3","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:57:38.458Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$183$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:58:36.214Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$184$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2d7912a1-d0be-41af-8c2c-d7786a761494","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:58:36.227Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$185$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:58:44.443Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$186$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:58:46.241Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$187$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:58:46.249Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$188$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:58:57.305Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$189$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:58:58.361Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$190$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"fc538926-ae82-4271-942d-079132c27cbc","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:58:58.465Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$191$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:59:05.656Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$192$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T00:59:06.376Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$193$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"921a8222-e657-4233-9cf4-c7c9ccb98eb3","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T00:59:06.378Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$194$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T00:59:13.628Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$195$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T01:01:10.130Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$196$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"2d7912a1-d0be-41af-8c2c-d7786a761494","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T01:01:10.132Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$197$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T01:01:17.796Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$198$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T01:01:18.183Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$199$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T01:01:18.195Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$200$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T01:01:25.951Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$201$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 1, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run started$paperclip$, NULL, $paperclip$2026-04-09T01:01:26.224Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$202$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"fc538926-ae82-4271-942d-079132c27cbc","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T01:01:26.229Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$203$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T01:01:39.614Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$205$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 2, $paperclip$adapter.invoke$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$adapter invocation$paperclip$, $paperclip${"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2","env":{"HOME":"/Users/jonathanborgia","PAPERCLIP_ROLE":"executor","PAPERCLIP_API_URL":"http://127.0.0.1:3110","PAPERCLIP_AGENT_ID":"921a8222-e657-4233-9cf4-c7c9ccb98eb3","PAPERCLIP_COMPANY_ID":"4a314bff-55a4-4939-bbb7-b3d73c7db1ce","PAPERCLIP_RESOLVED_COMMAND":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh"},"command":"/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-role-dispatch.sh","adapterType":"process","commandArgs":[]}$paperclip$, $paperclip$2026-04-09T01:01:40.333Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_run_events" ("id", "company_id", "run_id", "agent_id", "seq", "event_type", "stream", "level", "color", "message", "payload", "created_at") VALUES ($paperclip$206$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, 3, $paperclip$lifecycle$paperclip$, $paperclip$system$paperclip$, $paperclip$info$paperclip$, NULL, $paperclip$run succeeded$paperclip$, $paperclip${"status":"succeeded","exitCode":0}$paperclip$, $paperclip$2026-04-09T01:01:50.404Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.heartbeat_runs (69 rows)
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
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$fbd72cf9-902d-4444-851d-72d0cb66442c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:49:25.805Z$paperclip$, $paperclip$2026-04-08T23:49:36.321Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:49:25.802Z$paperclip$, $paperclip$2026-04-08T23:49:36.321Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$8ed4e084-fad9-444e-8b6e-d367a584a833$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/fbd72cf9-902d-4444-851d-72d0cb66442c.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$029c41771612add512dfb89e87c8c59634f1038a42335fc67e2481108e1f57f3$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
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
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$975b7659-138f-41ef-b15b-dda4620e52c1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:50:07.045Z$paperclip$, $paperclip$2026-04-08T23:50:07.969Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:50:07.040Z$paperclip$, $paperclip$2026-04-08T23:50:07.969Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$49b14019-ca3d-4057-b829-0af1da74de0c$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/975b7659-138f-41ef-b15b-dda4620e52c1.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$e1b45b0dcc751397aec55e7149ae1b8712dab94794ec8d86efaedf29d4ccd6e0$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$9091c797-9de8-4265-8ba1-53d1a4a7c5a2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T23:49:37.870Z$paperclip$, $paperclip$2026-04-08T23:49:38.250Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:49:37.865Z$paperclip$, $paperclip$2026-04-08T23:49:38.250Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$50a2af8f-5633-4bd7-a46c-c46576214069$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: planner route failed with HTTP 403.\n","stdout":""}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/9091c797-9de8-4265-8ba1-53d1a4a7c5a2.ndjson$paperclip$, $paperclip$415$paperclip$, $paperclip$b5bb421ef3c6727428421f0d3a01ba38b830968ed926193931b5f07068349050$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
$paperclip$, $paperclip$ERROR: planner route failed with HTTP 403.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$8851531f-6f6d-4e64-bf20-81da76ad4287$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:59:52.801Z$paperclip$, $paperclip$2026-04-09T00:00:03.157Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:59:52.799Z$paperclip$, $paperclip$2026-04-09T00:00:03.157Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$6b22e088-f1c8-41a6-83c7-bfa3544cfdd0$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e/8851531f-6f6d-4e64-bf20-81da76ad4287.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$91a0944756fe36a2487f2a9dffc3841e308b1c953a6eb1780df45d7618efb3e4$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:20:41.346Z$paperclip$, $paperclip$2026-04-09T00:21:21.431Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/442238da-cff2-4ac3-b9b9-d5de8c66f1fc","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/442238da-cff2-4ac3-b9b9-d5de8c66f1fc","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:20:41.340Z$paperclip$, $paperclip$2026-04-09T00:21:21.431Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$ba441868-5831-4407-af46-a1352fbc3d36$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/442238da-cff2-4ac3-b9b9-d5de8c66f1fc/e9b880c4-86d0-4e5c-aff9-dc795bf3c4eb.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$0dd936ce15299d7937d55b3e7dc4e9f7cc8e0459a5d699c2c62c5f7c28f25dcf$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/442238da-cff2-4ac3-b9b9-d5de8c66f1fc" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
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
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$e584143b-4376-4df8-ad18-e39d56538f45$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T23:15:07.321Z$paperclip$, $paperclip$2026-04-08T23:17:36.599Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"now":"2026-04-08T23:17:07.309Z","reason":"interval_elapsed","source":"scheduler","wakeReason":"heartbeat_timer","wakeSource":"timer","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:15:07.314Z$paperclip$, $paperclip$2026-04-08T23:17:36.599Z$paperclip$, $paperclip$system$paperclip$, $paperclip$4db66a0d-7f5f-4058-b8fd-7fe1c11a800f$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: Unexpected OpenClaw response; expected HEARTBEAT_OK marker.\n","stdout":""}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/e584143b-4376-4df8-ad18-e39d56538f45.ndjson$paperclip$, $paperclip$439$paperclip$, $paperclip$4b02eb7d091e94edbd87d9f902403d78da65bb15525784c4cb99204732d848a9$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
$paperclip$, $paperclip$ERROR: Unexpected OpenClaw response; expected HEARTBEAT_OK marker.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
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
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$1931d2cb-5d32-488b-b08e-af1a96395fd4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:27:28.208Z$paperclip$, $paperclip$2026-04-08T23:27:29.172Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:27:28.203Z$paperclip$, $paperclip$2026-04-08T23:27:29.172Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$ca0f7ce3-5f4d-474b-8479-67c78f2bc8b6$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/1931d2cb-5d32-488b-b08e-af1a96395fd4.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$b4a87f43099330acc66f45ca0108b428421f66a1217cbadd7ac74a6e1fac515a$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$9f6cf44e-d80b-4c20-a74b-a823346d6a92$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:27:14.107Z$paperclip$, $paperclip$2026-04-08T23:27:24.737Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:27:14.102Z$paperclip$, $paperclip$2026-04-08T23:27:24.737Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$cb2d6c8f-bac7-43b7-953e-c3ef4cf0b566$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/9f6cf44e-d80b-4c20-a74b-a823346d6a92.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$c302467a2bb722407fc1fe2331817d1f974afde32c75d1fc483525fd386e52b7$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$7ca4d6c1-2256-4c72-8e7f-a10820639d2b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:27:26.180Z$paperclip$, $paperclip$2026-04-08T23:27:27.326Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:27:26.175Z$paperclip$, $paperclip$2026-04-08T23:27:27.326Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$b04530ae-9844-4261-9a95-0089820f4a63$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/7ca4d6c1-2256-4c72-8e7f-a10820639d2b.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$e812179d76806cd7237d0591eda5a97e95ab0fed5acb0fafd20a6e1b8fd5f14c$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$5e696ca9-a951-4c4b-b48e-798da36e2d6a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$failed$paperclip$, $paperclip$2026-04-08T23:27:48.762Z$paperclip$, $paperclip$2026-04-08T23:27:48.810Z$paperclip$, $paperclip$Process exited with code 1$paperclip$, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:27:48.759Z$paperclip$, $paperclip$2026-04-08T23:27:48.810Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$be7d4bdc-efc7-4231-83c2-19ae83acd050$paperclip$, 1, NULL, NULL, $paperclip${"stderr":"ERROR: Unknown PAPERCLIP_ROLE 'invalid-role'.\n","stdout":""}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/5e696ca9-a951-4c4b-b48e-798da36e2d6a.ndjson$paperclip$, $paperclip$418$paperclip$, $paperclip$3b6f926cb7df9d0a1513f0a1ba2cf0e9072e01e87a64322fd29421cf28efc019$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
$paperclip$, $paperclip$ERROR: Unknown PAPERCLIP_ROLE 'invalid-role'.
$paperclip$, $paperclip$adapter_failed$paperclip$, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$0d203b1f-27a6-4587-b2e4-14033c6e6e90$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:34:06.944Z$paperclip$, $paperclip$2026-04-08T23:34:15.004Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:34:06.941Z$paperclip$, $paperclip$2026-04-08T23:34:15.004Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$785c0b19-c5ea-4216-bd3c-23ce0caefeb0$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/0d203b1f-27a6-4587-b2e4-14033c6e6e90.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$f3f551366d38ccb16b6de36f2707bb7dcdd03e1363155f706e66cf6dd4e95b83$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:27:50.804Z$paperclip$, $paperclip$2026-04-08T23:27:51.671Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:27:50.799Z$paperclip$, $paperclip$2026-04-08T23:27:51.671Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$dfacf0a5-0aa0-4c11-888e-d0f9ab042f49$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/ffcf359a-0e7d-4ffe-b5b8-15dbcb80a0c2.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$7e0a41944536f2d03133fbadb2dbaa2fcc45992d7fae193a80a1addf11d8a31c$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$d95f7cb1-addf-4b51-acd9-99fb9174ff3d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:34:16.999Z$paperclip$, $paperclip$2026-04-08T23:34:18.164Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:34:16.994Z$paperclip$, $paperclip$2026-04-08T23:34:18.164Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$08ffe34b-c1fa-4f6a-b973-ffc555cb8d3f$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/d95f7cb1-addf-4b51-acd9-99fb9174ff3d.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$4538be3cd399f783106b0def13c50e8236a67be05324c0ab96640d384f8b90c6$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$cb434aa3-a714-435d-ab59-358b9f7af79d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:34:19.037Z$paperclip$, $paperclip$2026-04-08T23:34:20.009Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:34:19.031Z$paperclip$, $paperclip$2026-04-08T23:34:20.009Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$67803413-0648-49e8-81d7-fa8d5fadbd73$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/cb434aa3-a714-435d-ab59-358b9f7af79d.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$03c2228a87b672e8dac2033619f7c799e84d6d026a48bd9afdc6e30270b76b87$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$399ca5c0-d18e-4791-a1fc-d839963249ab$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:37:05.982Z$paperclip$, $paperclip$2026-04-08T23:37:16.409Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:37:05.977Z$paperclip$, $paperclip$2026-04-08T23:37:16.409Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$7524e461-c52f-405a-8ac2-9bcbc9c3d0d5$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/399ca5c0-d18e-4791-a1fc-d839963249ab.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$1161b4797064181b92c215fed7e3cb286fbce6c4b52ef26f21fd503ffdc03a8d$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$edb1611c-8ba8-48e5-9edf-2c293af26112$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:37:18.044Z$paperclip$, $paperclip$2026-04-08T23:37:19.308Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:37:18.039Z$paperclip$, $paperclip$2026-04-08T23:37:19.308Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$2765cf7e-d4c0-49a0-b3e6-5a1f864547f5$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/edb1611c-8ba8-48e5-9edf-2c293af26112.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$9d86f1b9686f2ec6c88ad0556ea62a4e0a29eec6306bd8ad5d62369ae0acece1$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$d90b9f88-c86b-4974-b271-bfee76b12a38$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:37:20.070Z$paperclip$, $paperclip$2026-04-08T23:37:21.152Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:37:20.066Z$paperclip$, $paperclip$2026-04-08T23:37:21.152Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$fa074f4a-5a10-45c1-8173-2a95ec655b23$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/d90b9f88-c86b-4974-b271-bfee76b12a38.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$56870f3a36a32ddf6612e3eab3001ef40d373b3e2eb5c21f5d2998a7d3275fd6$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$18f1f4b3-b4dc-47ee-8c68-ee2425d025ff$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$assignment$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:42:07.112Z$paperclip$, $paperclip$2026-04-08T23:42:17.977Z$paperclip$, NULL, NULL, $paperclip${"source":"issue.create","taskId":"ae527462-ab1e-4362-a62d-28ae885a0563","issueId":"ae527462-ab1e-4362-a62d-28ae885a0563","taskKey":"ae527462-ab1e-4362-a62d-28ae885a0563","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","wakeReason":"issue_assigned","wakeSource":"assignment","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default","mode":"shared_workspace","source":"project_primary","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[],"executionWorkspaceId":"cd0efaf2-18d7-4649-8a11-fdf86ca9e7a2"}$paperclip$, $paperclip$2026-04-08T23:42:07.106Z$paperclip$, $paperclip$2026-04-08T23:42:17.977Z$paperclip$, $paperclip$system$paperclip$, $paperclip$0f5b58ef-2f23-429f-beb9-ad9399340206$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e/18f1f4b3-b4dc-47ee-8c68-ee2425d025ff.ndjson$paperclip$, $paperclip$281$paperclip$, $paperclip$eb9a8161e6caee7daf0ea9711c92f49af12fc1fe7d975d0a4938e1c4170a796b$paperclip$, false, $paperclip$[paperclip] Skipping saved session resume for task "ae527462-ab1e-4362-a62d-28ae885a0563" because wake reason is issue_assigned.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$42716d3a-802b-4216-b215-c87466194f04$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:42:19.307Z$paperclip$, $paperclip$2026-04-08T23:42:29.751Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:42:07.146Z$paperclip$, $paperclip$2026-04-08T23:42:29.751Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$71031a29-6b33-43f3-9e90-0571f7e37dae$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde/42716d3a-802b-4216-b215-c87466194f04.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$629080d82d503a87d3b049fcb5545e7b767f11f04d50f08866786a62290b72fa$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$93c22627-dabe-4a1b-9223-522c2cc222e7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:49:54.935Z$paperclip$, $paperclip$2026-04-08T23:50:04.628Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:49:54.932Z$paperclip$, $paperclip$2026-04-08T23:50:04.628Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$c743342f-b99c-4cae-aea9-5f35739817b9$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/93c22627-dabe-4a1b-9223-522c2cc222e7.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$43e88d4adb39c0df65f70c888860b83493d9738363c0a55b89c774ac8ed1f4d4$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$14a69919-d775-4da7-ba60-57804dd1da4f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$automation$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:42:17.989Z$paperclip$, $paperclip$2026-04-08T23:42:37.115Z$paperclip$, NULL, NULL, $paperclip${"source":"issue.comment","taskId":"ae527462-ab1e-4362-a62d-28ae885a0563","issueId":"ae527462-ab1e-4362-a62d-28ae885a0563","taskKey":"ae527462-ab1e-4362-a62d-28ae885a0563","commentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","wakeReason":"issue_commented","wakeSource":"automation","wakeCommentId":"9c0cef41-a46e-417d-9e3a-79890cc83409","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default","mode":"shared_workspace","source":"project_primary","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[],"executionWorkspaceId":"970c4218-33e3-40a3-96d5-c36a97365246"}$paperclip$, $paperclip$2026-04-08T23:42:17.981Z$paperclip$, $paperclip$2026-04-08T23:42:37.115Z$paperclip$, $paperclip$system$paperclip$, $paperclip$5c37f3a5-b148-40c3-88ad-aee7da8bec6a$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e/14a69919-d775-4da7-ba60-57804dd1da4f.ndjson$paperclip$, $paperclip$86$paperclip$, $paperclip$e14ffa0e1479f46da91e6bf34c58f1c60413d94674e4c4c0acdc207a0e68a417$paperclip$, false, $paperclip$HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ee0a5ea3-3941-411d-9e48-e0d539fcc45a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:21:21.601Z$paperclip$, $paperclip$2026-04-09T00:22:06.279Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/741f87c4-b981-4c85-8e3b-1ca97ff20df8","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/741f87c4-b981-4c85-8e3b-1ca97ff20df8","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:21:21.597Z$paperclip$, $paperclip$2026-04-09T00:22:06.279Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$969bc9c4-a14c-4d81-a364-dc76a673976d$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/741f87c4-b981-4c85-8e3b-1ca97ff20df8/ee0a5ea3-3941-411d-9e48-e0d539fcc45a.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$9ab5d18265288240210a04e0e6e8e058a76a8ddf046c7afc889c31bde9df9519$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/741f87c4-b981-4c85-8e3b-1ca97ff20df8" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:50:05.013Z$paperclip$, $paperclip$2026-04-08T23:50:06.208Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:50:05.009Z$paperclip$, $paperclip$2026-04-08T23:50:06.208Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$68401fa6-7167-48de-b7cb-c3384a081b23$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/27f3e06d-c8c8-450e-aa92-fcd0ed0d7c8b.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$651b4dabdbff6da5d0a9559f80ac10ed4c7d79c1d3df70db89adb79a021c42f7$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$728a0035-ce39-4c8e-939f-de94ef704195$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:01:27.449Z$paperclip$, $paperclip$2026-04-09T00:01:36.462Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:01:27.445Z$paperclip$, $paperclip$2026-04-09T00:01:36.462Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$f29dc5fc-be80-4887-a202-f63ad22d1908$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e/728a0035-ce39-4c8e-939f-de94ef704195.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$7fd337c8d56b6fed7f7b7f1cda3ec095289d0763296889654af2710425ee9646$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$5d94a597-3530-46ac-90d5-6ae8a3333b70$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$assignment$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:42:07.148Z$paperclip$, $paperclip$2026-04-08T23:42:19.180Z$paperclip$, NULL, NULL, $paperclip${"source":"issue.create","taskId":"6e292396-541e-424d-b5a7-229ea9408ad2","issueId":"6e292396-541e-424d-b5a7-229ea9408ad2","taskKey":"6e292396-541e-424d-b5a7-229ea9408ad2","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","wakeReason":"issue_assigned","wakeSource":"assignment","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/projects/4a314bff-55a4-4939-bbb7-b3d73c7db1ce/de79c85f-eb6e-482f-a840-6521ae2fb81d/_default","mode":"shared_workspace","source":"project_primary","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde","projectId":"de79c85f-eb6e-482f-a840-6521ae2fb81d","branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[],"executionWorkspaceId":"fae829a1-eea3-4f76-a0c4-fe4d05471d22"}$paperclip$, $paperclip$2026-04-08T23:42:07.129Z$paperclip$, $paperclip$2026-04-08T23:42:19.180Z$paperclip$, $paperclip$system$paperclip$, $paperclip$0a429d30-48c1-4b0b-a139-cae0c31351b5$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/788dfd8a-d944-4a3c-a1be-a8d30bb1dfde/5d94a597-3530-46ac-90d5-6ae8a3333b70.ndjson$paperclip$, $paperclip$281$paperclip$, $paperclip$6b1b811ec9b596457c72b311c62e794a851a56a8f7c3034071c29558b313fbfe$paperclip$, false, $paperclip$[paperclip] Skipping saved session resume for task "6e292396-541e-424d-b5a7-229ea9408ad2" because wake reason is issue_assigned.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$f4be3d38-1121-4492-815e-0a68e8322fb9$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:45:29.694Z$paperclip$, $paperclip$2026-04-08T23:45:31.113Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:45:29.691Z$paperclip$, $paperclip$2026-04-08T23:45:31.113Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$8195a8df-f075-41c6-999d-9ad7c9e5cd53$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/f4be3d38-1121-4492-815e-0a68e8322fb9.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$4d0a0bfe949e827445bc11553c2a1a298d793feee3d4a20e94d28f108f703e56$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$c2c6c258-83ae-442c-b3f2-01e6f61d69b7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:45:15.603Z$paperclip$, $paperclip$2026-04-08T23:45:29.121Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:45:15.600Z$paperclip$, $paperclip$2026-04-08T23:45:29.121Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$7edeb15d-04d7-4627-bedd-3108e53b1b39$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/c2c6c258-83ae-442c-b3f2-01e6f61d69b7.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$bd4657dca5193b2d9e1a7a87966dde922bb3a3b2083660cb9590b8deeffe1869$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$b05e922e-2b1d-40a4-a4f1-faaab940efb7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:45:31.727Z$paperclip$, $paperclip$2026-04-08T23:45:32.766Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:45:31.721Z$paperclip$, $paperclip$2026-04-08T23:45:32.766Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$2f9ad684-7897-420b-aea9-7c6c10cd6cfc$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/b05e922e-2b1d-40a4-a4f1-faaab940efb7.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$ebbb1892cec17dc37993c7aff7cda532e91a98d07541e2e8175f8935f160fba9$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$960dadd4-0767-4772-89ef-ca6b631ad08e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:47:13.047Z$paperclip$, $paperclip$2026-04-08T23:47:24.629Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:47:13.044Z$paperclip$, $paperclip$2026-04-08T23:47:24.629Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$3351a392-624a-412f-9476-209acf7f2bf4$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/960dadd4-0767-4772-89ef-ca6b631ad08e.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$90a99027a49cfac9c3e563e5322f0d9d2d0648ac5f94fb6af2265affb0fc01ad$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$7626730e-3518-417d-b896-02772b5454f1$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:47:25.107Z$paperclip$, $paperclip$2026-04-08T23:47:26.444Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:47:25.103Z$paperclip$, $paperclip$2026-04-08T23:47:26.444Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$35587f71-17d3-40f0-94fb-46644c059634$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:planner\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/94183066-a375-4870-be76-062cc80f34ce/7626730e-3518-417d-b896-02772b5454f1.ndjson$paperclip$, $paperclip$393$paperclip$, $paperclip$32433ed6e53de64817a9c79a5d2b0d2f47c708b7df405be50aec4820fb45d8bc$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/94183066-a375-4870-be76-062cc80f34ce" for this run.
HEARTBEAT_OK:planner
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:20:29.250Z$paperclip$, $paperclip$2026-04-09T00:20:40.912Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/c3c73efe-163e-4e63-9fd0-1286b4abf4cb","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/c3c73efe-163e-4e63-9fd0-1286b4abf4cb","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:20:29.246Z$paperclip$, $paperclip$2026-04-09T00:20:40.912Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$6d45a7a0-e4ad-4fef-9957-88126e841f3c$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/c3c73efe-163e-4e63-9fd0-1286b4abf4cb/f703a4e9-5f46-47ca-8e3d-9b1d5e4815e3.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$81330096ee626783b07a30fba676d526ce59b566cf246230a59a26efe8ed2f1a$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/c3c73efe-163e-4e63-9fd0-1286b4abf4cb" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$57311f9a-005d-473f-8721-057804752181$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:57:13.442Z$paperclip$, $paperclip$2026-04-08T23:57:23.971Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:57:13.437Z$paperclip$, $paperclip$2026-04-08T23:57:23.971Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$2a6aea40-3363-446a-862b-820f14be8b3f$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e/57311f9a-005d-473f-8721-057804752181.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$0ef8c835f22c4d4284e632ed4516434d8be4297d8f2e616e57aabcdfd520edbd$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2ffc0df3-83be-4fcf-a7ee-73e20570ea4e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$36f86cfa-2d67-482c-a972-8f6f16411323$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-08T23:47:27.138Z$paperclip$, $paperclip$2026-04-08T23:47:28.262Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-08T23:47:27.132Z$paperclip$, $paperclip$2026-04-08T23:47:28.262Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$5f5da724-852b-4b61-be2b-506174725e91$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:embedding\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/865d128d-1e01-4daa-b571-f61b81d31097/36f86cfa-2d67-482c-a972-8f6f16411323.ndjson$paperclip$, $paperclip$395$paperclip$, $paperclip$5f3871d4912c216fc201727fa5b2b0c78c03ecde0ac28fe85e46d4c51de61bea$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/865d128d-1e01-4daa-b571-f61b81d31097" for this run.
HEARTBEAT_OK:embedding
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$6cab6277-1e54-41cf-9e13-b3710307d2c6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:22:07.816Z$paperclip$, $paperclip$2026-04-09T00:22:15.706Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4cfa9f9c-5211-4182-a630-f389ed61a3f4","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4cfa9f9c-5211-4182-a630-f389ed61a3f4","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:22:07.811Z$paperclip$, $paperclip$2026-04-09T00:22:15.706Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$7b6deaf7-5a55-4da0-b0cc-a66000d983db$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/4cfa9f9c-5211-4182-a630-f389ed61a3f4/6cab6277-1e54-41cf-9e13-b3710307d2c6.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$21a9453713eb62ca9433b2afc895ef335c7a9aa2e7621c2892466a1e9f72612a$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4cfa9f9c-5211-4182-a630-f389ed61a3f4" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$4639161e-3b0e-49c6-9bfb-d602f80b50d3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:41:42.056Z$paperclip$, $paperclip$2026-04-09T00:41:50.401Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:41:42.053Z$paperclip$, $paperclip$2026-04-09T00:41:50.401Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$60792975-a9fe-4e3e-a595-725a800e109c$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/7a2913ec-480f-40a2-920a-a047bc578025/4639161e-3b0e-49c6-9bfb-d602f80b50d3.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$94e9637c3412f3ae90ac14a18e9bb97ab39ccd8bc5c82ec862c390a39d6693d6$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$afbbc44d-c545-4135-b86f-4fb5e907bf6c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:58:46.231Z$paperclip$, $paperclip$2026-04-09T00:58:57.301Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:58:46.228Z$paperclip$, $paperclip$2026-04-09T00:58:57.301Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$8fe7c72d-1cef-49e2-9354-b2b7f84a42d5$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66/afbbc44d-c545-4135-b86f-4fb5e907bf6c.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$38a6be6746f4afe7787c66d20f38daf53b2fe1fa99b38adbfdab9019a5a5132f$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$90aabf9c-d168-477a-aa83-7cd69cc68ef2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:59:06.360Z$paperclip$, $paperclip$2026-04-09T00:59:13.626Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:59:06.357Z$paperclip$, $paperclip$2026-04-09T00:59:13.626Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$4a651a2f-c7cd-4a13-afa4-6963a96a8fed$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/921a8222-e657-4233-9cf4-c7c9ccb98eb3/90aabf9c-d168-477a-aa83-7cd69cc68ef2.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$e60e984d155104f8cdaad1efbb0e114ae48c2b116b005ba2c41aff6e4ceab901$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$6a46ffd0-a59b-4650-83bb-4bc6a696a808$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:41:52.122Z$paperclip$, $paperclip$2026-04-09T00:41:59.654Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:41:52.117Z$paperclip$, $paperclip$2026-04-09T00:41:59.654Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$5c157ca7-8701-4fbf-b4ac-32ba1570d933$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e/6a46ffd0-a59b-4650-83bb-4bc6a696a808.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$104a5fcf32e50ae0953f65d9a89fab78a1effe7d85ed3cf06b454d48888bde33$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$10b30ea7-388c-4cbb-8912-66042dba351a$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:58:58.297Z$paperclip$, $paperclip$2026-04-09T00:59:05.653Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:58:58.293Z$paperclip$, $paperclip$2026-04-09T00:59:05.653Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$4a05a240-02a3-4ad8-b32e-2d075eed5b51$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/fc538926-ae82-4271-942d-079132c27cbc/10b30ea7-388c-4cbb-8912-66042dba351a.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$d0f48df2f9eae9f127bacf15bd20d0b3f68d7d121a5d5ad3a2f8721df3ab33c7$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:42:00.183Z$paperclip$, $paperclip$2026-04-09T00:42:07.739Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:42:00.175Z$paperclip$, $paperclip$2026-04-09T00:42:07.739Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$649a413c-386f-4238-b559-4f35920636b9$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/58be556b-c711-47a6-8339-a8df890bb083/fe2ad565-3b3e-4dbf-9d6b-b7d0d0bffd82.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$cb952024701b3acd1052aa84c8fc3b68253873707b64a09627afacbaef336099$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ab479954-4c09-438c-8c24-02a5587b0db4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:44:32.501Z$paperclip$, $paperclip$2026-04-09T00:44:40.000Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:44:32.496Z$paperclip$, $paperclip$2026-04-09T00:44:40.000Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$dcfead73-fac9-4126-9f0b-2b5c8d9a8fc8$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/837263a1-004a-4baa-b7ad-3d6b6a63a464/ab479954-4c09-438c-8c24-02a5587b0db4.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$ef0eb588fe78123cc7aa453e13b2696b9d35e6efd8683b14dc315d31c3ee0fe2$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:42:08.257Z$paperclip$, $paperclip$2026-04-09T00:42:15.463Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:42:08.251Z$paperclip$, $paperclip$2026-04-09T00:42:15.463Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$be475d78-28bc-4dd8-b7e3-7a02a0a17363$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/837263a1-004a-4baa-b7ad-3d6b6a63a464/ca586b9b-58bc-4cb6-ac8f-a4ec2e8f9184.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$d6d82401d9a2a20498bac5c1b676bff131cc1bd36abf3aefd6034219db07c79a$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/837263a1-004a-4baa-b7ad-3d6b6a63a464" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$041fa294-7908-4817-ab49-d35d6320ba75$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:44:04.315Z$paperclip$, $paperclip$2026-04-09T00:44:15.238Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:44:04.312Z$paperclip$, $paperclip$2026-04-09T00:44:15.238Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$b0cbadcd-7e84-453d-82fc-e23408ca41fb$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/7a2913ec-480f-40a2-920a-a047bc578025/041fa294-7908-4817-ab49-d35d6320ba75.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$1230b6eb38038dcbf3d656146d0593c3d71c82195d90e625a015ca9db67742d7$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/7a2913ec-480f-40a2-920a-a047bc578025" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$efb0c4a9-a727-465d-8917-9d33fb3f45b7$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$timer$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:50:07.601Z$paperclip$, $paperclip$2026-04-09T00:50:19.181Z$paperclip$, NULL, NULL, $paperclip${"now":"2026-04-09T00:50:07.571Z","reason":"interval_elapsed","source":"scheduler","wakeReason":"heartbeat_timer","wakeSource":"timer","wakeTriggerDetail":"system","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:50:07.593Z$paperclip$, $paperclip$2026-04-09T00:50:19.181Z$paperclip$, $paperclip$system$paperclip$, $paperclip$85166446-6e10-4d6c-9a36-3b9ba8b1d33f$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/b82a9601-f0c3-41b5-9a15-571d868b6b1e/efb0c4a9-a727-465d-8917-9d33fb3f45b7.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$35d09cceac1767fec4f8548e6ee0cf755536ea2eeada00df81a282ade65b2d20$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/b82a9601-f0c3-41b5-9a15-571d868b6b1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$426c6268-54de-4277-bfd0-2c29ce44ed5b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:44:16.382Z$paperclip$, $paperclip$2026-04-09T00:44:23.935Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:44:16.376Z$paperclip$, $paperclip$2026-04-09T00:44:23.935Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$6531a7f8-cb4b-42d4-88ec-997fb9fee340$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e/426c6268-54de-4277-bfd0-2c29ce44ed5b.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$fde4b4203b930a422c0cbd7304ab4665a86e81499b080126bf2ab2029efa7877$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/9090f2f8-0164-4ae7-8a0b-869ab02a9f1e" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$782eee52-15cd-4399-93fb-986fc3b805a3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T01:01:26.213Z$paperclip$, $paperclip$2026-04-09T01:01:39.612Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T01:01:26.210Z$paperclip$, $paperclip$2026-04-09T01:01:39.612Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$9ad5be99-0299-4e07-87e2-12225d974739$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/fc538926-ae82-4271-942d-079132c27cbc/782eee52-15cd-4399-93fb-986fc3b805a3.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$74287e35b27b3a5ef6d63ae9de9252fb04f6ae9aa7e79d38aa27519c09995e92$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$2fabda23-06e2-4ce2-b839-abb68932f32c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T01:01:10.120Z$paperclip$, $paperclip$2026-04-09T01:01:17.794Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T01:01:10.117Z$paperclip$, $paperclip$2026-04-09T01:01:17.794Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$6f4f9fca-b2fe-4b47-b78b-5d1d04dd704b$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2d7912a1-d0be-41af-8c2c-d7786a761494/2fabda23-06e2-4ce2-b839-abb68932f32c.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$0569078198813e93d5bf71cdce69659a0f93b4d88aa7f784826c49ae9ed656d1$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$7c8ee723-def8-459b-a7b5-5ddc9643a6b4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:44:24.442Z$paperclip$, $paperclip$2026-04-09T00:44:31.526Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:44:24.436Z$paperclip$, $paperclip$2026-04-09T00:44:31.526Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$050545b2-4cd5-416f-9a89-ce660bb77b2b$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/58be556b-c711-47a6-8339-a8df890bb083/7c8ee723-def8-459b-a7b5-5ddc9643a6b4.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$e281bd102f0fed9201b3d0a00d7d05c1a34e1bc1d207b6469c3a6552e0e79f4d$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/58be556b-c711-47a6-8339-a8df890bb083" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$79273d04-da43-4b1e-9856-eefc50db42ab$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T01:01:18.169Z$paperclip$, $paperclip$2026-04-09T01:01:25.949Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T01:01:18.165Z$paperclip$, $paperclip$2026-04-09T01:01:25.949Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$d00be332-2763-4faf-9e81-efb3a217c2b6$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66/79273d04-da43-4b1e-9856-eefc50db42ab.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$1eafbd06a5d4988a7ae80e1cc7d865ea908fab31a0e4bd8e82aede4734479afa$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$0bcbaa9c-1a63-4af9-a633-9077ab27fba6$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:57:02.174Z$paperclip$, $paperclip$2026-04-09T00:57:12.908Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:57:02.166Z$paperclip$, $paperclip$2026-04-09T00:57:12.908Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$5ad9dbc1-b4d0-481b-81b6-1877e65adc77$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2d7912a1-d0be-41af-8c2c-d7786a761494/0bcbaa9c-1a63-4af9-a633-9077ab27fba6.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$25da83535592f2dd85e75ac29382b02e2d9e3835cd6ae9ab507fde3eb9b8c506$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:57:38.418Z$paperclip$, $paperclip$2026-04-09T00:57:44.782Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:57:38.414Z$paperclip$, $paperclip$2026-04-09T00:57:44.782Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$44a7aafe-9e99-4d43-95d5-126f8eabfbe6$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/921a8222-e657-4233-9cf4-c7c9ccb98eb3/c91ca9b6-bca3-4fad-9ed4-54c2e6f380f4.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$6b8c5fed674ad7b0f0bd7526769b08ebd52e69e41c479a73403b9c408de3cbdf$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$5218d8c5-d8d8-41f6-a8f4-5555d68a799e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T01:01:40.319Z$paperclip$, $paperclip$2026-04-09T01:01:50.402Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T01:01:40.315Z$paperclip$, $paperclip$2026-04-09T01:01:50.402Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$9c4cf280-2f1b-4c7c-8dc6-0c00f57207ee$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/921a8222-e657-4233-9cf4-c7c9ccb98eb3/5218d8c5-d8d8-41f6-a8f4-5555d68a799e.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$acdf1c1f49318e5079df7dd15a2d4b825503381b433e2f3fbe1d1cf3d21cfa17$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/921a8222-e657-4233-9cf4-c7c9ccb98eb3" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$e0a0150c-2a80-4da9-8d0b-159843d78e4b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:57:14.268Z$paperclip$, $paperclip$2026-04-09T00:57:24.349Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:57:14.264Z$paperclip$, $paperclip$2026-04-09T00:57:24.349Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$41c3a68f-c4c0-468d-9117-efadd54c7db8$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66/e0a0150c-2a80-4da9-8d0b-159843d78e4b.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$557a3f1ef4133a9a308c7f89edc6f597a82a932156ffa7b9f1a7b10e7570b83d$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$e96be8eb-393c-499e-bd49-b29665c6cac3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:57:26.344Z$paperclip$, $paperclip$2026-04-09T00:57:36.432Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:57:26.339Z$paperclip$, $paperclip$2026-04-09T00:57:36.432Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$f36b239a-e8ce-4cfb-b9e2-c4dcf4944edf$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/fc538926-ae82-4271-942d-079132c27cbc/e96be8eb-393c-499e-bd49-b29665c6cac3.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$a27e0c5844e455e685b41c8b9ee2135d9e80ce0596a40d2e8dc3a771b4a8e806$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/fc538926-ae82-4271-942d-079132c27cbc" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."heartbeat_runs" ("id", "company_id", "agent_id", "invocation_source", "status", "started_at", "finished_at", "error", "external_run_id", "context_snapshot", "created_at", "updated_at", "trigger_detail", "wakeup_request_id", "exit_code", "signal", "usage_json", "result_json", "session_id_before", "session_id_after", "log_store", "log_ref", "log_bytes", "log_sha256", "log_compressed", "stdout_excerpt", "stderr_excerpt", "error_code", "process_pid", "process_started_at", "retry_of_run_id", "process_loss_retry_count") VALUES ($paperclip$edbcd97e-6d2e-4782-ac62-3a6718a1830d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$on_demand$paperclip$, $paperclip$succeeded$paperclip$, $paperclip$2026-04-09T00:58:36.096Z$paperclip$, $paperclip$2026-04-09T00:58:44.440Z$paperclip$, NULL, NULL, $paperclip${"actorId":"local-board","wakeSource":"on_demand","triggeredBy":"board","wakeTriggerDetail":"manual","paperclipWorkspace":{"cwd":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","mode":"shared_workspace","source":"agent_home","repoRef":null,"repoUrl":null,"strategy":"project_primary","agentHome":"/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494","projectId":null,"branchName":null,"workspaceId":null,"worktreePath":null},"paperclipWorkspaces":[]}$paperclip$, $paperclip$2026-04-09T00:58:36.085Z$paperclip$, $paperclip$2026-04-09T00:58:44.440Z$paperclip$, $paperclip$manual$paperclip$, $paperclip$95cb83b4-dc8f-420d-aebb-a0819e4417e2$paperclip$, 0, NULL, NULL, $paperclip${"stderr":"","stdout":"HEARTBEAT_OK:executor\n"}$paperclip$, NULL, NULL, $paperclip$local_file$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce/2d7912a1-d0be-41af-8c2c-d7786a761494/edbcd97e-6d2e-4782-ac62-3a6718a1830d.ndjson$paperclip$, $paperclip$394$paperclip$, $paperclip$81231fad5bd6dc0843a58fac56a6431f73628ea64888027e94b502a350f61c23$paperclip$, false, $paperclip$[paperclip] No project or prior session workspace was available. Using fallback workspace "/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/workspaces/2d7912a1-d0be-41af-8c2c-d7786a761494" for this run.
HEARTBEAT_OK:executor
$paperclip$, $paperclip$$paperclip$, NULL, NULL, NULL, NULL, 0);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.instance_settings (1 rows)
INSERT INTO "public"."instance_settings" ("id", "singleton_key", "experimental", "created_at", "updated_at", "general") VALUES ($paperclip$a6f3130b-0615-4501-93f7-b231b1cee76e$paperclip$, $paperclip$default$paperclip$, $paperclip${}$paperclip$, $paperclip$2026-04-08T22:06:20.136Z$paperclip$, $paperclip$2026-04-08T22:06:20.136Z$paperclip$, $paperclip${}$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.instance_user_roles (1 rows)
INSERT INTO "public"."instance_user_roles" ("id", "user_id", "role", "created_at", "updated_at") VALUES ($paperclip$e15abad1-c181-45dc-99ec-d06f64cbbd05$paperclip$, $paperclip$local-board$paperclip$, $paperclip$instance_admin$paperclip$, $paperclip$2026-04-08T22:06:07.131Z$paperclip$, $paperclip$2026-04-08T22:06:07.131Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.issue_comments (1 rows)
INSERT INTO "public"."issue_comments" ("id", "company_id", "issue_id", "author_agent_id", "author_user_id", "body", "created_at", "updated_at", "created_by_run_id") VALUES ($paperclip$9c0cef41-a46e-417d-9e3a-79890cc83409$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$Delegated implementation to EngineeringBuilder via child issue FOR-4$paperclip$, $paperclip$2026-04-08T23:42:07.123Z$paperclip$, $paperclip$2026-04-08T23:42:07.123Z$paperclip$, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.issue_read_states (1 rows)
INSERT INTO "public"."issue_read_states" ("id", "company_id", "issue_id", "user_id", "last_read_at", "created_at", "updated_at") VALUES ($paperclip$ea6972c0-43e5-4ccf-a8df-70ed262a8006$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:39:56.060Z$paperclip$, $paperclip$2026-04-08T22:07:35.639Z$paperclip$, $paperclip$2026-04-09T00:39:56.060Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.issues (8 rows)
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$b7119a46-e4d8-4990-8745-ae4af3e76ea8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, NULL, $paperclip$Hire your first engineer and create a hiring plan$paperclip$, $paperclip$You are the CEO. You set the direction for the company.

- hire a founding engineer
- write a hiring plan
- break the roadmap into concrete tasks and start delegating work$paperclip$, $paperclip$todo$paperclip$, $paperclip$medium$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T22:07:35.301Z$paperclip$, $paperclip$2026-04-08T22:07:35.533Z$paperclip$, 1, $paperclip$FOR-1$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$edb84357-b6e8-4ee6-a7f8-1d6d8b24b9be$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, NULL, NULL, $paperclip$P2.1 minimal OpenClaw seam proof$paperclip$, $paperclip$Trigger one Paperclip heartbeat that executes OpenClaw as the runtime adapter and returns OPENCLAW_OK.$paperclip$, $paperclip$todo$paperclip$, $paperclip$high$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T22:08:35.338Z$paperclip$, $paperclip$2026-04-08T22:08:35.385Z$paperclip$, 2, $paperclip$FOR-2$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$6e292396-541e-424d-b5a7-229ea9408ad2$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, $paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, $paperclip$B3.4 delegated workflow child task$paperclip$, $paperclip$Implement delegated check and report completion marker.$paperclip$, $paperclip$todo$paperclip$, $paperclip$high$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T23:42:07.105Z$paperclip$, $paperclip$2026-04-08T23:42:19.278Z$paperclip$, 4, $paperclip$FOR-4$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$ae527462-ab1e-4362-a62d-28ae885a0563$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, NULL, NULL, $paperclip$B3.4 delegated workflow parent task$paperclip$, $paperclip$ChiefOfStaff delegates a routing validation implementation task to EngineeringBuilder.$paperclip$, $paperclip$todo$paperclip$, $paperclip$high$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-08T23:42:07.098Z$paperclip$, $paperclip$2026-04-08T23:42:37.130Z$paperclip$, 3, $paperclip$FOR-3$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$4e6fc7c9-51b2-43db-9cb9-fc97645e30fb$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, NULL, NULL, $paperclip$isolation-a-1775693165$paperclip$, $paperclip$isolation test A$paperclip$, $paperclip$todo$paperclip$, $paperclip$low$paperclip$, NULL, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-09T00:06:05.037Z$paperclip$, $paperclip$2026-04-09T00:06:05.037Z$paperclip$, 5, $paperclip$FOR-5$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$691f08c7-71ea-42ad-a938-1a27298d564b$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, NULL, NULL, NULL, $paperclip$isolation-b-1775693165$paperclip$, $paperclip$isolation test B$paperclip$, $paperclip$todo$paperclip$, $paperclip$low$paperclip$, NULL, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-09T00:06:05.048Z$paperclip$, $paperclip$2026-04-09T00:06:05.048Z$paperclip$, 1, $paperclip$FORA-1$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$f36f37fb-bfd7-4e75-84a5-1fdb3dd19c90$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, NULL, NULL, $paperclip$isolation-a-1775693297$paperclip$, $paperclip$isolation test A$paperclip$, $paperclip$todo$paperclip$, $paperclip$low$paperclip$, NULL, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-09T00:08:17.065Z$paperclip$, $paperclip$2026-04-09T00:08:17.065Z$paperclip$, 6, $paperclip$FOR-6$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."issues" ("id", "company_id", "project_id", "goal_id", "parent_id", "title", "description", "status", "priority", "assignee_agent_id", "created_by_agent_id", "created_by_user_id", "request_depth", "billing_code", "started_at", "completed_at", "cancelled_at", "created_at", "updated_at", "issue_number", "identifier", "hidden_at", "checkout_run_id", "execution_run_id", "execution_agent_name_key", "execution_locked_at", "assignee_user_id", "assignee_adapter_overrides", "execution_workspace_settings", "project_workspace_id", "execution_workspace_id", "execution_workspace_preference", "origin_kind", "origin_id", "origin_run_id") VALUES ($paperclip$91e4551c-5c8d-42e8-bc6e-37713b3751f4$paperclip$, $paperclip$00ca3ed6-7ad2-43f1-a862-5d5295bbac0c$paperclip$, NULL, NULL, NULL, $paperclip$isolation-b-1775693297$paperclip$, $paperclip$isolation test B$paperclip$, $paperclip$todo$paperclip$, $paperclip$low$paperclip$, NULL, NULL, $paperclip$local-board$paperclip$, 0, NULL, NULL, NULL, NULL, $paperclip$2026-04-09T00:08:17.069Z$paperclip$, $paperclip$2026-04-09T00:08:17.069Z$paperclip$, 2, $paperclip$FORA-2$paperclip$, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $paperclip$manual$paperclip$, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.principal_permission_grants (19 rows)
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$8673791c-9f87-42a8-ab28-88b8cf667276$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$b82a9601-f0c3-41b5-9a15-571d868b6b1e$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T22:07:24.534Z$paperclip$, $paperclip$2026-04-08T22:07:24.534Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$cfff51aa-ba79-41ca-bbfc-30f0d925034b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$94183066-a375-4870-be76-062cc80f34ce$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T22:08:35.336Z$paperclip$, $paperclip$2026-04-08T22:08:35.336Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$9dd1c429-d2b0-457f-9b43-8e0594175d8b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$865d128d-1e01-4daa-b571-f61b81d31097$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T23:27:06.185Z$paperclip$, $paperclip$2026-04-08T23:27:06.185Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$946c50f2-f49f-4a88-b8af-a00a177ff25c$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$2ffc0df3-83be-4fcf-a7ee-73e20570ea4e$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T23:41:48.594Z$paperclip$, $paperclip$2026-04-08T23:41:48.594Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$5faa7384-8e2c-4f17-868b-3ea2a68fb853$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$788dfd8a-d944-4a3c-a1be-a8d30bb1dfde$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T23:41:48.601Z$paperclip$, $paperclip$2026-04-08T23:41:48.601Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$d133e388-0b6d-49c8-9cba-9448736c6fb8$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$e486e9c1-7fb6-4671-b1db-3f0d66c19121$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T23:41:48.607Z$paperclip$, $paperclip$2026-04-08T23:41:48.607Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$d61086e7-106c-4814-906e-d4b08cd857a3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$265c953e-789f-41d2-a483-20c71c0430bf$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-08T23:41:48.616Z$paperclip$, $paperclip$2026-04-08T23:41:48.616Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$91015954-0b76-48b5-9826-2ac878b91330$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$c3c73efe-163e-4e63-9fd0-1286b4abf4cb$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:20:03.196Z$paperclip$, $paperclip$2026-04-09T00:20:03.196Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$3525816b-8c99-4706-8ba3-dabb0e853e9b$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$442238da-cff2-4ac3-b9b9-d5de8c66f1fc$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:20:03.202Z$paperclip$, $paperclip$2026-04-09T00:20:03.202Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$faef7b88-fb66-4f4e-92a9-d4e5517237b3$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$741f87c4-b981-4c85-8e3b-1ca97ff20df8$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:20:03.207Z$paperclip$, $paperclip$2026-04-09T00:20:03.207Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$42628010-33a7-42c1-94d7-350c54418463$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$4cfa9f9c-5211-4182-a630-f389ed61a3f4$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:20:03.212Z$paperclip$, $paperclip$2026-04-09T00:20:03.212Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$35191e8e-9f63-4512-ad42-d71ce54edb5e$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$7a2913ec-480f-40a2-920a-a047bc578025$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:41:42.038Z$paperclip$, $paperclip$2026-04-09T00:41:42.038Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$afe1636f-c58e-45ac-91e5-afc3ffe53615$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$9090f2f8-0164-4ae7-8a0b-869ab02a9f1e$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:41:42.042Z$paperclip$, $paperclip$2026-04-09T00:41:42.042Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$ee678d51-fa62-41fc-acb0-fb4fa3dbf1e0$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$58be556b-c711-47a6-8339-a8df890bb083$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:41:42.046Z$paperclip$, $paperclip$2026-04-09T00:41:42.046Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$1185dc2f-d386-4c5c-9de0-b5466f9c91bd$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$837263a1-004a-4baa-b7ad-3d6b6a63a464$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:41:42.049Z$paperclip$, $paperclip$2026-04-09T00:41:42.049Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$2bccef72-0929-4580-9825-05d49dbeb1fa$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$2d7912a1-d0be-41af-8c2c-d7786a761494$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:57:02.157Z$paperclip$, $paperclip$2026-04-09T00:57:02.157Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$f10bbbff-05cc-468b-921c-3b5b40b3d56d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$4f57e8cc-ebd2-4e02-b9e8-a6ffd3b16e66$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:57:14.257Z$paperclip$, $paperclip$2026-04-09T00:57:14.257Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$6aa009f5-5588-4bf5-bf70-c1d1a3ca33bc$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$fc538926-ae82-4271-942d-079132c27cbc$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:57:26.334Z$paperclip$, $paperclip$2026-04-09T00:57:26.334Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
INSERT INTO "public"."principal_permission_grants" ("id", "company_id", "principal_type", "principal_id", "permission_key", "scope", "granted_by_user_id", "created_at", "updated_at") VALUES ($paperclip$34fdc497-79da-4175-b541-4bfd5c25d10f$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, $paperclip$agent$paperclip$, $paperclip$921a8222-e657-4233-9cf4-c7c9ccb98eb3$paperclip$, $paperclip$tasks:assign$paperclip$, NULL, $paperclip$local-board$paperclip$, $paperclip$2026-04-09T00:57:38.407Z$paperclip$, $paperclip$2026-04-09T00:57:38.407Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.projects (1 rows)
INSERT INTO "public"."projects" ("id", "company_id", "goal_id", "name", "description", "status", "lead_agent_id", "target_date", "created_at", "updated_at", "color", "archived_at", "execution_workspace_policy", "pause_reason", "paused_at") VALUES ($paperclip$de79c85f-eb6e-482f-a840-6521ae2fb81d$paperclip$, $paperclip$4a314bff-55a4-4939-bbb7-b3d73c7db1ce$paperclip$, NULL, $paperclip$Onboarding$paperclip$, NULL, $paperclip$in_progress$paperclip$, NULL, NULL, $paperclip$2026-04-08T22:07:35.283Z$paperclip$, $paperclip$2026-04-08T22:07:35.283Z$paperclip$, $paperclip$#6366f1$paperclip$, NULL, NULL, NULL, NULL);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Data for: public.user (1 rows)
INSERT INTO "public"."user" ("id", "name", "email", "email_verified", "image", "created_at", "updated_at") VALUES ($paperclip$local-board$paperclip$, $paperclip$Board$paperclip$, $paperclip$local@paperclip.local$paperclip$, true, NULL, $paperclip$2026-04-08T22:06:07.111Z$paperclip$, $paperclip$2026-04-08T22:06:07.111Z$paperclip$);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

-- Sequence values
SELECT setval('"public"."heartbeat_run_events_id_seq"', 206, true);
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900

COMMIT;
-- paperclip statement breakpoint 69f6f3f1-42fd-46a6-bf17-d1d85f8f3900
