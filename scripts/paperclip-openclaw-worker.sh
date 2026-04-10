#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPERCLIP_ROLE="${PAPERCLIP_ROLE:-executor}" "${SCRIPT_DIR}/paperclip-role-dispatch.sh"
