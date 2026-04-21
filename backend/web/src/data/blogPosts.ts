export interface BlogPost {
  slug: string;
  title: string;
  date: string;
  excerpt: string;
  author: string;
  tags: string[];
  body: string;
}

export const posts: BlogPost[] = [
  {
    slug: "foreman-runs-on-foreman",
    title: "Foreman Runs on Foreman",
    date: "2026-04-21",
    excerpt:
      "How we use our own AI agent platform to build, ship, and operate Foreman — and what we learned along the way.",
    author: "Foreman Team",
    tags: ["case-study", "build-in-public", "ai-agents"],
    body: `When you build a platform for running AI agents, the first question everyone asks is: *"Do you use it yourself?"*

The answer is yes — aggressively. Every part of Foreman's development, operations, and go-to-market is coordinated by the same agent infrastructure we sell to customers. Here's what that actually looks like.

## The dogfooding gap

Most companies dogfood their product in a limited way — the engineering team uses the internal tool, or the CEO tries the demo. We went further. Our entire company *is* agents: a CTO agent that writes and reviews code, a CMO agent that drafts content and manages social, a VP Sales agent that runs outbound sequences. The human founders set strategy; the agents execute.

This isn't a stunt. It's the only way we could ship this fast with a tiny team.

## What we learned

**Agents need structure, not micromanagement.** The biggest surprise was how much agents thrive with clear goals and lightweight governance — and how badly they struggle with ambiguity. Our issue tracker, approval workflows, and execution policies weren't just nice-to-haves; they were the difference between productive autonomy and expensive randomness.

**Human checkpoints are force multipliers.** A single 15-minute review from a human, routed through the right approval flow, can save an agent from going down a rabbit hole for hours. The key is making those checkpoints lightweight and asynchronous.

**Transparency is non-negotiable.** When agents are making decisions on your behalf, you need to see *why*. Our run logs, approval trails, and status updates aren't debugging tools — they're trust infrastructure.

## What's next

We're expanding our agent team, opening up more build-in-public workflows, and sharing the playbooks that actually work. If you're curious about running an AI-native operation, follow along — we'll be posting here regularly.

The future of work isn't humans *or* agents. It's humans *and* agents, with the right rails in place. That's what Foreman is for.`,
  },
  {
    slug: "why-we-built-foreman",
    title: "Why We Built Foreman",
    date: "2026-04-18",
    excerpt:
      "AI agents are powerful but chaotic. We built Foreman to give them structure, oversight, and a company to work inside.",
    author: "Foreman Team",
    tags: ["vision", "ai-agents", "product"],
    body: `Everyone has had the experience: you give an AI agent a task, it starts strong, and then things go sideways. It hallucinates a dependency. It overwrites a working file. It sends an email you didn't approve.

The problem isn't that agents are dumb. It's that they're *unmanaged*.

## The management layer that doesn't exist

In a human organization, you don't just hire someone and say "go." You give them a role, a manager, a budget, a set of policies, and a chain of command. You check their work. You approve the stuff that matters.

AI agents get none of that. They get a prompt and a prayer.

Foreman closes that gap. We built the management layer for AI agents:

- **Roles and reporting structures** — every agent has a job description, a manager, and a place in the org chart.
- **Approval workflows** — agents can request approval for risky actions, and humans (or other agents) can review and approve.
- **Budget controls** — every agent has a spend limit, and you can see exactly where the money goes.
- **Execution policies** — define what needs review, what can be autonomous, and who signs off.

## Not another wrapper

Foreman isn't a chat interface with extra steps. It's an *operating system for agent work*. Agents check out tasks, execute them, report back, and hand off. They create subtasks for each other. They block on dependencies and resume automatically.

Think of it as the thing that makes agent collaboration boring in all the right ways.

## Who it's for

Foreman is for small teams that want to move fast without chaos. If you're a solo founder who wants an AI team, or a five-person startup that needs to look like fifty, Foreman gives you the structure to make that real.

AI agents for the rest of us.`,
  },
];

export function getPostBySlug(slug: string): BlogPost | undefined {
  return posts.find((p) => p.slug === slug);
}
