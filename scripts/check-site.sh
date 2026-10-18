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

assert_href() {
  local file="$1"
  local target="$2"

  if ! grep -Fq -- "href=\"$target\"" "$file" \
    && ! grep -Fq -- "href='$target'" "$file" \
    && ! grep -Eq -- "href=${target}([[:space:]>]|$)" "$file"; then
    printf 'Missing navigation link in %s: %s\n' "$file" "$target" >&2
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

readonly HOME_PAGE="public/index.html"
readonly BOOK_INDEX="public/buku/index.html"
readonly EXAMPLE_BOOK="public/buku/contoh-buku/index.html"
readonly CHAPTER_ONE="public/buku/contoh-buku/bab-1-awal-perjalanan/index.html"
readonly CHAPTER_TWO="public/buku/contoh-buku/bab-2-menghadapi-rintangan/index.html"
readonly CHAPTER_THREE="public/buku/contoh-buku/bab-3-pelajaran-utama/index.html"

assert_href "$HOME_PAGE" "/read-summary/buku/"
assert_href "$HOME_PAGE" "/read-summary/buku/contoh-buku/"
assert_href "$BOOK_INDEX" "/read-summary/buku/contoh-buku/"

for chapter_path in \
  "/read-summary/buku/contoh-buku/bab-1-awal-perjalanan/" \
  "/read-summary/buku/contoh-buku/bab-2-menghadapi-rintangan/" \
  "/read-summary/buku/contoh-buku/bab-3-pelajaran-utama/"; do
  assert_href "$EXAMPLE_BOOK" "$chapter_path"
done

assert_href "$CHAPTER_ONE" "/read-summary/buku/contoh-buku/"
assert_href "$CHAPTER_ONE" "/read-summary/buku/contoh-buku/bab-2-menghadapi-rintangan/"
assert_href "$CHAPTER_ONE" "/read-summary/buku/contoh-buku/bab-3-pelajaran-utama/"

assert_href "$CHAPTER_TWO" "/read-summary/buku/contoh-buku/"
assert_href "$CHAPTER_TWO" "/read-summary/buku/contoh-buku/bab-1-awal-perjalanan/"
assert_href "$CHAPTER_TWO" "/read-summary/buku/contoh-buku/bab-3-pelajaran-utama/"

assert_href "$CHAPTER_THREE" "/read-summary/buku/contoh-buku/"
assert_href "$CHAPTER_THREE" "/read-summary/buku/contoh-buku/bab-1-awal-perjalanan/"
assert_href "$CHAPTER_THREE" "/read-summary/buku/contoh-buku/bab-2-menghadapi-rintangan/"

assert_contains "$CHAPTER_TWO" "Contoh Buku" "parent book label"
assert_contains "$CHAPTER_TWO" "Bab 1: Awal Perjalanan" "previous sibling chapter label"
assert_contains "$CHAPTER_TWO" "Bab 3: Pelajaran Utama" "next sibling chapter label"

printf 'Site checks passed.\n'
