# Terminology: Base vs Project

## Base
The persistent, top-level environment a user operates within. Has an overall objective, a team of agents, and long-lived context. One workspace = one base. The user sets up a base and everything else (projects, tasks, deliverables) lives inside it.

- User-facing term: "base" (lowercase)
- Database: scoped by `workspace_slug` (do not rename)
- Never refer to a base as a "project," "workspace" (in UI copy), "mission," or "campaign"

## Project
A bounded, completable unit of work inside a base. Has a goal, tasks, assigned agents, and deliverables. Has a lifecycle (proposed → approved → in progress → completed).

- User-facing term: "project" (lowercase)
- Database: `agent_projects` table (do not rename)
- Never refer to a project as a "base," "effort," or "initiative"

## Hierarchy
Base → Projects → Tasks → Deliverables

## Rules
- `workspace_slug` is the multi-tenancy key. Do not rename.
- Do not rename database tables or columns for this terminology change.
- All user-facing copy uses lowercase "base" and "project."
- Agent prompts must use "base" for the environment and "project" for units of work.
