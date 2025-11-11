#!/usr/bin/env bash
# Populate age encryption cache with current repository state
# This ensures clean filter returns the same encrypted content for unchanged files

set -euo pipefail

CACHE_DIR="${GIT_DIR:-.git}/age-cache"
SMUDGE_SCRIPT="${GIT_DIR:-.git}/age-smudge.sh"

mkdir -p "${CACHE_DIR}"

# Find all files with age filter from .gitattributes
age_files=$(git ls-files | git check-attr --stdin filter | grep ': filter: age$' | cut -d: -f1)

for file in ${age_files}; do
  # Skip if file doesn't exist in index
  if ! git ls-files --error-unmatch "${file}" >/dev/null 2>&1; then
    continue
  fi

  # Get encrypted content from index
  encrypted=$(git show :"${file}")

  # Decrypt to get plaintext
  decrypted=$(echo "${encrypted}" | bash "${SMUDGE_SCRIPT}")

  # Calculate content hash
  content_hash=$(echo -n "${decrypted}" | shasum -a 256 | cut -d' ' -f1)
  cache_file="${CACHE_DIR}/${content_hash}"

  # Cache the encrypted version from index
  echo "${encrypted}" > "${cache_file}"

  echo "Cached: ${file} -> ${content_hash}"
done

entry_count=$(find "${CACHE_DIR}" -type f | wc -l | tr -d ' ')
echo "Cache populated with ${entry_count} entries"
