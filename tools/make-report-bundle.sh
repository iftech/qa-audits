#!/bin/sh
# Usage: tools/make-report-bundle.sh <tag> <report.md> [output.zip]
# Run from the repo root. Works with macOS (BSD) and GNU tools.
set -eu

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: $0 <tag> <report.md> [output.zip]" >&2
  exit 2
fi
tag=$1
report=$2
bundle_name=$(printf '%s' "$tag" | tr '/' '-')
out=${3:-$bundle_name.zip}

git rev-parse --verify --quiet "$tag^{commit}" >/dev/null || { echo "tag not found: $tag" >&2; exit 1; }
git cat-file -e "$tag:$report" 2>/dev/null || { echo "report not in $tag: $report" >&2; exit 1; }

if command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$@"; }
else
  sha256() { sha256sum "$@"; }
fi

# Relative links to evidence/, cut to the run folder: evidence/<project>/<subject>/<issue>-<slug>/<run>/
paths=$(git show "$tag:$report" \
  | awk '
    {
      sub(/^[[:blank:]]*\[[^]]+]:[[:blank:]]*/, "](")
      while (match($0, /]\(<?(\.\.\/)*evidence\/[^)>#?[:space:]]*/)) {
        link = substr($0, RSTART, RLENGTH)
        $0 = substr($0, RSTART + RLENGTH)
        sub(/^]\(<?(\.\.\/)*/, "", link)
        print link
      }
    }' \
  | cut -d/ -f1-5 \
  | sort -u)
[ -n "$paths" ] || { echo "no evidence links found in $report" >&2; exit 1; }

assets=${report%.md}
if git cat-file -e "$tag:$assets" 2>/dev/null; then
  paths="$paths
$assets"
fi

for p in $paths; do
  git cat-file -e "$tag:$p" 2>/dev/null || { echo "linked path not in $tag: $p" >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/$bundle_name"
git archive "$tag" "$report" $paths | tar -x -C "$work/$bundle_name"

(
  cd "$work/$bundle_name"
  find . -type f ! -path './SHA256SUMS' | sed 's#^\./##' | LC_ALL=C sort | while IFS= read -r f; do
    sha256 "$f"
  done > SHA256SUMS
)

case $out in
  /*) dest=$out ;;
  *) dest=$(pwd)/$out ;;
esac
rm -f "$dest"
(cd "$work" && zip -qr -X "$dest" "$bundle_name")

echo "Wrote $out"
echo "Folders:"
echo "$paths" | sed 's/^/  /'
sha256 "$out"
