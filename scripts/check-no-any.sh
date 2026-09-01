#!/usr/bin/env bash
set -euo pipefail

matches="$(rg --line-number --glob '*.luau' '\bany\b' src tests || true)"

if [[ -n "$matches" ]]; then
    echo "Explicit 'any' is forbidden in authored Luau. Use a concrete type, a union, or unknown plus validation."
    echo "$matches"
    exit 1
fi
