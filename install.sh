#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
[[ "${1:-}" == "-f" || "${1:-}" == "--force" ]] && FORCE=1

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
# add more below
EOF

echo
echo "Done."