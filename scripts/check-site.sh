#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf public
hugo_args=(--gc --minify)
if [[ -n "${SITE_BASE_URL:-}" ]]; then
  hugo_args+=(--baseURL "$SITE_BASE_URL")
fi
hugo "${hugo_args[@]}"

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

assert_matches() {
  local file="$1"
  local expected="$2"
  local description="$3"

  if ! grep -Eq -- "$expected" "$file"; then
    printf 'Missing %s in %s matching: %s\n' "$description" "$file" "$expected" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  local description="$3"

  if grep -Fq -- "$unexpected" "$file"; then
    printf 'Unexpected %s in %s: %s\n' "$description" "$file" "$unexpected" >&2
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

assert_single_h1() {
  local file="$1"
  local count

  count="$({ grep -oE -- '<h1([[:space:]>])' "$file" || true; } | wc -l)"
  if [[ "$count" -ne 1 ]]; then
    printf 'Expected one rendered H1 in %s, found %s\n' "$file" "$count" >&2
    exit 1
  fi
}

readonly -a EXPECTED_PAGES=(
  "public/index.html"
  "public/404.html"
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
readonly NOT_FOUND_PAGE="public/404.html"
readonly BOOK_INDEX="public/buku/index.html"
readonly EXAMPLE_BOOK="public/buku/contoh-buku/index.html"
readonly CHAPTER_ONE="public/buku/contoh-buku/bab-1-awal-perjalanan/index.html"
readonly CHAPTER_TWO="public/buku/contoh-buku/bab-2-menghadapi-rintangan/index.html"
readonly CHAPTER_THREE="public/buku/contoh-buku/bab-3-pelajaran-utama/index.html"

assert_href "$HOME_PAGE" "/read-summary/buku/"
assert_href "$HOME_PAGE" "/read-summary/buku/contoh-buku/"
assert_href "$BOOK_INDEX" "/read-summary/buku/contoh-buku/"
assert_matches "$HOME_PAGE" '<html[^>]*lang="?id(-ID)?"?([[:space:]>])' "Indonesian HTML language"
assert_matches "$HOME_PAGE" '<link[^>]*rel="?canonical"?[^>]*href="?https://thomasbudiarjo\.github\.io/read-summary/"?' "canonical project URL"

assert_contains "$NOT_FOUND_PAGE" "Halaman tidak ditemukan" "Indonesian not-found heading"
assert_contains "$NOT_FOUND_PAGE" "Halaman yang Anda cari tidak ada atau telah dipindahkan." "Indonesian not-found message"
assert_href "$NOT_FOUND_PAGE" "/read-summary/"

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

assert_contains "$CHAPTER_TWO" "Lewati ke konten" "Indonesian skip link"
assert_contains "$CHAPTER_TWO" "Cari..." "Indonesian search placeholder"
assert_contains "$CHAPTER_TWO" "aria-label=Tutup" "Indonesian search-dialog close label"
assert_contains "$CHAPTER_TWO" "Di halaman ini" "Indonesian table of contents label"
assert_contains "$CHAPTER_TWO" "Edit halaman ini di GitHub →" "Indonesian edit link"
assert_contains "$CHAPTER_TWO" "Kembali ke atas" "Indonesian back-to-top label"
assert_contains "$CHAPTER_TWO" "Ganti tema" "Indonesian theme-toggle label"
assert_contains "$CHAPTER_TWO" "Hak cipta Read Summary." "timeless Indonesian footer copyright"
assert_not_contains "$CHAPTER_TWO" "Hextra GitHub Homepage" "English powered-by tooltip"

for content_page in \
  "$BOOK_INDEX" \
  "$EXAMPLE_BOOK" \
  "$CHAPTER_ONE" \
  "$CHAPTER_TWO" \
  "$CHAPTER_THREE"; do
  assert_single_h1 "$content_page"
done

printf 'Site checks passed.\n'
