#!/usr/bin/env bash
# Link (or unlink) every Stow package in this repo into $HOME.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target="${HOME:?HOME is not set}"
action="${1:-install}"

shopt -s nullglob
packages=()
for dir in "$repo_dir"/*/; do
    packages+=("$(basename "${dir%/}")")
done

if (( ${#packages[@]} == 0 )); then
    echo "No Stow packages found in $repo_dir" >&2
    exit 1
fi

case "$action" in
    install)    flags=(--verbose) ;;
    unlink)     flags=(--verbose --delete) ;;
    restow)     flags=(--verbose --restow) ;;
    dry-run)    flags=(--verbose --no) ;;
    *)
        echo "Usage: $0 [install|unlink|restow|dry-run]" >&2
        exit 1
        ;;
esac

echo "Packages: ${packages[*]}"
stow --dir="$repo_dir" --target="$target" "${flags[@]}" "${packages[@]}"
