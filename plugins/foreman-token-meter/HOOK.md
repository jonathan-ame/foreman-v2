---
name: foreman-token-meter
description: "Report per-completion usage to Paperclip and Foreman backend."
metadata:
  {
    "openclaw":
      {
        "emoji": "💸",
        "events": ["llm_output"],
      },
  }
---

# Foreman Token Meter Hook

This plugin uses the typed OpenClaw plugin hook `llm_output` to capture usage
for each model completion and forward metering data to external systems.
