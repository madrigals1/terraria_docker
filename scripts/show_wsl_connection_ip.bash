#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    # shellcheck disable=SC1091
    source "$PROJECT_DIR/.env"
else
    echo ".env file not found" >&2
    exit 1
fi

: "${PORT:?PORT is not set in .env}"

IP=$(hostname -I | awk '{print $1}')

echo "IP: $IP"
echo "PORT: $PORT"
