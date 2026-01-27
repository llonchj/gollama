#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is dirty. Commit or stash changes before updating llama.cpp." >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <llama.cpp tag or commit>" >&2
  exit 1
fi

REF="$1"

git subtree pull --prefix=llama.cpp https://github.com/ggerganov/llama.cpp "$REF" --squash

echo "Updated llama.cpp subtree to ${REF}"
