#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# 1) Split $PATH into an array
IFS=':' read -ra DIRS <<< "$PATH"

# 2) Build a parallel “options” array that adds “[root required]” where needed
OPTIONS=()
for d in "${DIRS[@]}"; do
  warn=""
  [[ "$d" == /bin || "$d" == /sbin ]] && warn=" [root required]"
  OPTIONS+=("$d$warn")
done

# 3) Prompt with `select`
echo "Choose install directory:"
PS3="Enter number (1-${#OPTIONS[@]}): "
select opt in "${OPTIONS[@]}"; do
  # If opt is non-empty, it’s a valid choice
  if [[ -n "$opt" ]]; then
    TARGET_DIR="${DIRS[$REPLY-1]}"
    break
  else
    echo "Invalid selection. Try again."
  fi
done

# 4) Use it
echo "Installing files into: $TARGET_DIR"

count=0

find "${script_dir}" -type f -name "*.install" | while read -r line; do filename=$(basename ${line%.install}); echo "Installing $filename..."; cp "$line" "$TARGET_DIR/$filename"; count=$((count + 1)); done

echo "Installed $count scripts successfully."
