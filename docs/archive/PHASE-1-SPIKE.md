> Archived reference: This document describes the pre-migration RunPod pod architecture and is retained for historical context.

# Phase 1 Spike: OpenClaw + RunPod Secure Cloud Roster

## Goal

Install OpenClaw locally, provision a three-pod RunPod Secure Cloud inference
roster, and validate end-to-end health across executor, planner, and embedding.

## Success Criterion

Phase 1 is successful when:

- All three pods are provisioned as healthy Secure Cloud pods:
  - executor: `Qwen/Qwen3-14B-AWQ`
  - planner: `Qwen/Qwen3-30B-A3B-Instruct-2507`
  - embedding: `Qwen/Qwen3-Embedding-8B`
- `./scripts/smoke-test.sh` exits `0` only after executor, planner, and
  embedding checks each pass.
- OpenClaw chat in WebChat (`http://127.0.0.1:18789`) routes to executor cleanly
  with no silent fallback to Anthropic/OpenAI.

Current validation status (2026-04-08): all three pods are healthy, automated
smoke passes, and manual WebChat verification is complete.

## Explicitly Out of Scope

- Paperclip integration
- Frontend reskin
- Multi-tenant architecture
- Docker, Railway, or cloud deployment
- Changes to existing `foreman/` source
- Custom CoS/Chiefs/Specialists hierarchy and scheduled tasks
- Supabase integration

## Open Questions For Phase 2

- Multi-tenant session and credential model
- Paperclip integration boundary and handoff contract
- Frontend reskin strategy and migration sequencing
- Hosting/deployment story after local spike validation

## History

The original Phase 1 attempt targeted a single pre-existing executor pod. That
infrastructure no longer exists. The corrected Phase 1 scope provisions a fresh
three-pod roster from a clean RunPod slate. Router/coder/VLM/executor-MoE/
planner-heavy roles were intentionally removed to keep surviving endpoints
always-on without unnecessary cost growth.
