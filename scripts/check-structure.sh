#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-.}"
cd "$repo_root"

failed=0

# Root markdown policy
bad_root_markdown=()
while IFS= read -r file; do
  base="$(basename "$file")"
  if [[ "$base" != "README.md" && "$base" != "CONTRIBUTING.md" ]]; then
    bad_root_markdown+=("$base")
  fi
done < <(find . -maxdepth 1 -type f -name "*.md" -print)

if (( ${#bad_root_markdown[@]} > 0 )); then
  failed=1
  echo "Unexpected root-level markdown files:"
  for f in "${bad_root_markdown[@]}"; do
    echo "  - $f"
  done
fi

# Disallow duplicate-style swift names like "Foo 2.swift"
bad_swift_names=()
while IFS= read -r file; do
  name="$(basename "$file")"
  if [[ "$name" =~ [[:space:]][0-9]+\.swift$ ]]; then
    bad_swift_names+=("$file")
  fi
done < <(find r2rscorecards -type f -name "*.swift" -print 2>/dev/null || true)

if (( ${#bad_swift_names[@]} > 0 )); then
  failed=1
  echo "Disallowed Swift filename pattern detected (e.g. '* 2.swift'):"
  for f in "${bad_swift_names[@]}"; do
    echo "  - $f"
  done
fi

# Disallow AI-style status markdown naming outside archive
bad_named_markdown=()
while IFS= read -r file; do
  if [[ "$file" == *"docs/archive/ai-sessions/"* ]]; then
    continue
  fi
  base="$(basename "$file")"
  if [[ "$base" =~ (_FINAL_STATUS\.md|_DONE\.md|CHANGES_APPLIED\.md|TODO_.*\.md)$ ]]; then
    bad_named_markdown+=("$file")
  fi
done < <(find . -type f -name "*.md" -print)

if (( ${#bad_named_markdown[@]} > 0 )); then
  failed=1
  echo "Disallowed markdown naming pattern detected outside archive:"
  for f in "${bad_named_markdown[@]}"; do
    echo "  - $f"
  done
fi

if (( failed > 0 )); then
  echo "Repository structure checks failed."
  exit 1
fi

echo "Repository structure checks passed."
