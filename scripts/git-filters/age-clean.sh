#!/usr/bin/env bash
# Git clean filter: encrypt file content for storage in repository
# Uses content-based caching to avoid non-deterministic re-encryption
# Encrypts to multiple recipients: personal key + CI key

set -euo pipefail

CACHE_DIR="${GIT_DIR:-.git}/age-cache"
AGE_BIN=~/.local/share/mise/installs/age/1.2.1/age/age
RECIPIENTS=(
  age1c459u9ehvrjrsh6v2sun69mw3p6apuku8cjh9q8eeax2etr439pshvnn4z
  age1h3cwe6tflreqda3dqkv2qucgzswkwp8w39nqt7089tw6kmpfn9sqmln47m
)

# Read stdin content
content=$(cat)

# Calculate content hash for cache key
content_hash=$(echo -n "${content}" | shasum -a 256 | cut -d' ' -f1)
cache_file="${CACHE_DIR}/${content_hash}"

# If cached encrypted version exists, use it
if [[ -f "${cache_file}" ]]; then
  cat "${cache_file}"
  exit 0
fi

# Encrypt content
mkdir -p "${CACHE_DIR}"
encrypted=$(echo -n "${content}" | "${AGE_BIN}" --encrypt \
  --recipient "${RECIPIENTS[0]}" \
  --recipient "${RECIPIENTS[1]}" \
  --armor)

# Cache the encrypted version
echo -n "${encrypted}" > "${cache_file}"

# Output encrypted content
echo -n "${encrypted}"