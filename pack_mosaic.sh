#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$repo_dir/tools/package_windows_release.py" --repo "$repo_dir" "$@"
