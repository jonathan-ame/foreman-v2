#!/usr/bin/env bash
set -euo pipefail

echo "Stopping OpenClaw gateway..."
openclaw gateway stop
openclaw gateway status || true
