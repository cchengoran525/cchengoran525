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
  size=0
  code=000

  for attempt in $(seq 1 "$retries"); do
    result=$(curl -L --retry 2 --retry-all-errors --retry-delay "$retry_delay" -o "$tmpfile" -w "%{http_code} %{size_download}" -s "$url" || true)
    code=$(echo "$result" | awk '{print $1}')
    size=$(echo "$result" | awk '{print $2}')

    if [ "$code" = "200" ] && [ "$size" -ge "$min_size" ]; then
      break
    fi

    if [ "$attempt" -lt "$retries" ]; then
      echo "Attempt $attempt failed for $url -> $code (${size} bytes); retrying..."
      sleep "$retry_delay"
    fi
  done

  rm -f "$tmpfile"

  if [ "$code" != "200" ] || [ "$size" -lt "$min_size" ]; then
    echo "Asset too small or unavailable after $retries attempts: $url ($code, ${size} bytes)"
    exit 1
  fi
done
