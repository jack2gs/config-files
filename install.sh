#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
[[ "${1:-}" == "-f" || "${1:-}" == "--force" ]] && FORCE=1

# ---------- helpers ----------

link_file() {
  local src="$1" dest="$2"
  local full_src full_dest dest_dir

  if [[ "$src" = /* ]]; then full_src="$src"; else full_src="$DIR/$src"; fi
  if [[ ! -e "$full_src" ]]; then
    echo "  skip:    source not found: $full_src" >&2
    return 0
  fi
  full_src="$(readlink -f "$full_src")"

  full_dest="$HOME/$dest"
  dest_dir="$(dirname "$full_dest")"

  if [[ -L "$full_dest" || -e "$full_dest" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      rm -f "$full_dest"
      echo "  replace: $full_dest"
    else
      echo "  skip:    already exists: $full_dest (use --force)"
      return 0
    fi
  fi

  if [[ ! -d "$dest_dir" ]]; then
    mkdir -p "$dest_dir"
    echo "  mkdir:   $dest_dir"
  fi

  ln -s "$full_src" "$full_dest"
  echo "  link:    $full_dest -> $full_src"
}

vscode_user_settings() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Code/User/settings.json" ;;
    Linux)  echo "$HOME/.config/Code/User/settings.json" ;;
    *)      echo "" ;;
  esac
}

merge_vscode_settings() {
  local src="$1"
  local dest
  dest="$(vscode_user_settings)"

  if [[ -z "$dest" ]]; then
    echo "  warn:    unsupported OS for VS Code merge"
    return 0
  fi

  local full_src="$DIR/$src"
  if [[ ! -f "$full_src" ]]; then
    echo "  skip:    source not found: $full_src"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  # If dest doesn't exist, just copy it
  if [[ ! -f "$dest" ]]; then
    cp "$full_src" "$dest"
    echo "  create:  $dest"
    return 0
  fi

  # Backup before touching it
  cp "$dest" "${dest}.bak"

  if command -v jq >/dev/null 2>&1; then
    # recursive merge: values from $full_src win over $dest
    jq -s '.[0] * .[1]' "$dest" "$full_src" > "${dest}.tmp"
    mv "${dest}.tmp" "$dest"
    echo "  merge:   $dest  (backup: ${dest}.bak)"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$dest" "$full_src" <<'PY'
import json, sys

dest_path, src_path = sys.argv[1], sys.argv[2]
with open(dest_path) as f: dest = json.load(f)
with open(src_path) as f: src  = json.load(f)

def deep_merge(a, b):
    for k, v in b.items():
        if k in a and isinstance(a[k], dict) and isinstance(v, dict):
            deep_merge(a[k], v)
        else:
            a[k] = v
    return a

with open(dest_path, "w") as f:
    json.dump(deep_merge(dest, src), f, indent=4)
PY
    echo "  merge:   $dest  (via python, backup: ${dest}.bak)"
  else
    echo "  warn:    neither jq nor python3 found; skipping VS Code merge"
    rm -f "${dest}.bak"
  fi
}

# ---------- main ----------

echo "Linking from $DIR"
echo

while IFS=: read -r src dest; do
  [[ -z "$src" || "$src" == \#* ]] && continue
  src="${src#"${src%%[![:space:]]*}"}";   src="${src%"${src##*[![:space:]]}"}"
  dest="${dest#"${dest%%[![:space:]]*}"}"; dest="${dest%"${dest##*[![:space:]]}"}"
  link_file "$src" "$dest"
done <<'EOF'
ideavimrc:.ideavimrc
vscvimrc:.vscvimrc
# add more entries below
EOF

echo
echo "Merging VS Code settings..."
merge_vscode_settings "vsc_settings.json"

echo
echo "Done."