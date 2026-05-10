#!/usr/bin/env bash
set -euo pipefail

min_size="${ASSET_VERIFY_MIN_SIZE:-1000}"
sleep_seconds="${ASSET_VERIFY_SLEEP:-10}"
retries="${ASSET_VERIFY_RETRIES:-5}"
retry_delay="${ASSET_VERIFY_RETRY_DELAY:-10}"

if [ "$#" -eq 0 ]; then
  echo "No URLs provided for verification."
  exit 1
fi

echo "Waiting for assets to propagate..."
sleep "$sleep_seconds"

for url in "$@"; do
  echo "Checking $url"
  tmpfile=$(mktemp)
  curl -L --retry "$retries" --retry-all-errors --retry-delay "$retry_delay" -o "$tmpfile" "$url"
  size=$(wc -c < "$tmpfile")
  rm -f "$tmpfile"
  if [ "$size" -lt "$min_size" ]; then
    echo "Asset too small: $url ($size bytes)"
    exit 1
  fi
done
