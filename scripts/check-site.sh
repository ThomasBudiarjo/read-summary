#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf public
hugo --gc --minify

assert_page() {
  local page="$1"

  if [[ ! -f "$page" ]]; then
    printf 'Missing rendered page: %s\n' "$page" >&2
    exit 1
  fi
}

assert_contains() {
  local file="$1"
  local expected="$2"
  local description="$3"

  if ! grep -Fq -- "$expected" "$file"; then
    printf 'Missing %s in %s: %s\n' "$description" "$file" "$expected" >&2
    exit 1
  fi
}

readonly -a EXPECTED_PAGES=(
  "public/index.html"
  "public/buku/index.html"
  "public/buku/contoh-buku/index.html"
  "public/buku/contoh-buku/bab-1-awal-perjalanan/index.html"
  "public/buku/contoh-buku/bab-2-menghadapi-rintangan/index.html"
  "public/buku/contoh-buku/bab-3-pelajaran-utama/index.html"
)

for page in "${EXPECTED_PAGES[@]}"; do
  assert_page "$page"
done

if ! grep -REq 'href="?/read-summary/' public; then
  printf 'Missing rendered link with the /read-summary/ project prefix.\n' >&2
  exit 1
fi

readonly EXAMPLE_CHAPTER="public/buku/contoh-buku/bab-2-menghadapi-rintangan/index.html"
assert_contains "$EXAMPLE_CHAPTER" "Contoh Buku" "parent book label"
assert_contains "$EXAMPLE_CHAPTER" "Bab 1: Awal Perjalanan" "previous sibling chapter label"
assert_contains "$EXAMPLE_CHAPTER" "Bab 3: Pelajaran Utama" "next sibling chapter label"

printf 'Site checks passed.\n'
