#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [TEMPLATE_FILE]" >&2
  exit 1
fi

TEMPLATE="${1:-/dev/stdin}"

# Arrays to preserve prompt order:
declare -a VAR_KEYS
declare -A VAR_PROMPTS VAR_VALUES
declare -a TEMPLATE_LINES

# 1) Read through the template, harvesting #<VAR> prompts and storing other lines
while IFS= read -r line; do
  if [[ $line =~ ^#\<([^>]+)\>\ (.*) ]]; then
    key="${BASH_REMATCH[1]}"
    desc="${BASH_REMATCH[2]}"
    # Avoid duplicate prompts if the same placeholder appears twice
    if [[ -z "${VAR_PROMPTS[$key]:-}" ]]; then
      VAR_KEYS+=("$key")
      VAR_PROMPTS["$key"]="$desc"
    fi
  else
    TEMPLATE_LINES+=("$line")
  fi
done < "$TEMPLATE"

tot=${#VAR_KEYS[@]}
count=1

# 2) Prompt the user for each variable
for key in "${VAR_KEYS[@]}"; do
  read -rp "[$count/$tot] ${VAR_PROMPTS[$key]}: " val
  VAR_VALUES["$key"]="$val"
  count=$(( count + 1 ))
done

# 3) Emit the filled-in template
for line in "${TEMPLATE_LINES[@]}"; do
  out="$line"
  for key in "${VAR_KEYS[@]}"; do
    out="${out//<$key>/${VAR_VALUES[$key]}}"
  done
  echo "$out"
done
