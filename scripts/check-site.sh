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

assert_chart() {
  local file="$1"
  local chart_id="$2"
  local source="$3"
  local printed_page="$4"
  local figure
  local caption
  local expected
  shift 4

  if ! figure="$(
    awk -v chart_id="$chart_id" '
      BEGIN { RS = "</figure>" }
      index($0, "<figure") && (index($0, "id=chart-" chart_id " ") || index($0, "id=chart-" chart_id ">") || index($0, "id=\"chart-" chart_id "\"")) {
        print
        found = 1
        exit
      }
      END {
        if (!found) {
          exit 1
        }
      }
    ' "$file"
  )"; then
    printf 'Missing chart figure in %s: chart-%s\n' "$file" "$chart_id" >&2
    exit 1
  fi

  if ! grep -Eq -- '<figure[^>]*class=("([^"]*[[:space:]])?read-chart([[:space:]][^"]*)?"|read-chart)([[:space:]>])' <<<"$figure"; then
    printf 'Missing semantic read-chart figure markup in %s: chart-%s\n' "$file" "$chart_id" >&2
    exit 1
  fi

  if ! grep -Fq -- '<figcaption' <<<"$figure"; then
    printf 'Missing chart figcaption in %s: chart-%s\n' "$file" "$chart_id" >&2
    exit 1
  fi

  caption="${figure##*<figcaption}"
  if ! grep -Fq -- "Sumber" <<<"$caption" || ! grep -Fq -- "$source" <<<"$caption"; then
    printf 'Missing chart source in %s for chart-%s: %s\n' "$file" "$chart_id" "$source" >&2
    exit 1
  fi

  if ! grep -Fq -- "hlm. $printed_page" <<<"$caption"; then
    printf 'Missing printed-page caption in %s for chart-%s: hlm. %s\n' \
      "$file" "$chart_id" "$printed_page" >&2
    exit 1
  fi

  for expected in "$@"; do
    if ! grep -Fq -- "$expected" <<<"$figure"; then
      printf 'Missing representative chart output in %s for chart-%s: %s\n' \
        "$file" "$chart_id" "$expected" >&2
      exit 1
    fi
  done
}

assert_source_data_details() {
  local file="$1"
  local printed_page="$2"
  local title="Data sumber grafik (hlm. $printed_page)"
  local count
  local details
  local expected
  shift 2

  count="$({ grep -Fo -- "$title" "$file" || true; } | wc -l)"
  if [[ "$count" -ne 1 ]]; then
    printf 'Expected one source-data details block in %s for hlm. %s, found %s\n' \
      "$file" "$printed_page" "$count" >&2
    exit 1
  fi

  if ! details="$(
    awk -v title="$title" '
      BEGIN { RS = "</details>" }
      index($0, title) {
        start = match($0, /<details[[:space:]>]/)
        if (start > 0) {
          print substr($0, start)
        } else {
          print
        }
        found = 1
        exit
      }
      END {
        if (!found) {
          exit 1
        }
      }
    ' "$file"
  )"; then
    printf 'Missing source-data details markup in %s for hlm. %s\n' \
      "$file" "$printed_page" >&2
    exit 1
  fi

  count="$({ grep -oE -- '<details([[:space:]>])' <<<"$details" || true; } | wc -l)"
  if [[ "$count" -ne 1 ]]; then
    printf 'Expected one details element in source-data block in %s for hlm. %s, found %s\n' \
      "$file" "$printed_page" "$count" >&2
    exit 1
  fi

  if grep -Eq -- '<details[^>]*[[:space:]]open([[:space:]=>]|$)' <<<"$details"; then
    printf 'Expected closed source-data details block in %s for hlm. %s\n' \
      "$file" "$printed_page" >&2
    exit 1
  fi

  count="$({ grep -oE -- '<table([[:space:]>])' <<<"$details" || true; } | wc -l)"
  if [[ "$count" -ne 1 ]]; then
    printf 'Expected one source-data table in %s for hlm. %s, found %s\n' \
      "$file" "$printed_page" "$count" >&2
    exit 1
  fi

  for expected in "$@"; do
    if ! grep -Fq -- "$expected" <<<"$details"; then
      printf 'Missing preserved source data in %s for hlm. %s: %s\n' \
        "$file" "$printed_page" "$expected" >&2
      exit 1
    fi
  done
}

assert_compiled_css_matches() {
  local expected="$1"
  local description="$2"
  local css_file

  shopt -s nullglob
  for css_file in public/css/compiled/*.css public/css/*.css; do
    if [[ -f "$css_file" ]] && grep -Eq -- "$expected" "$css_file"; then
      return
    fi
  done

  printf 'Missing %s in compiled site CSS matching: %s\n' "$description" "$expected" >&2
  exit 1
}

readonly -a EXPECTED_PAGES=(
  "public/index.html"
  "public/404.html"
  "public/buku/index.html"
  "public/buku/contoh-buku/index.html"
  "public/buku/contoh-buku/bab-1-awal-perjalanan/index.html"
  "public/buku/contoh-buku/bab-2-menghadapi-rintangan/index.html"
  "public/buku/contoh-buku/bab-3-pelajaran-utama/index.html"
  "public/buku/decoding-corporate-innovation/prolog/index.html"
  "public/buku/decoding-corporate-innovation/bab-1-innovation-disconnect/index.html"
  "public/buku/decoding-corporate-innovation/bab-2-rethinking-corporate-innovation/index.html"
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
readonly INNOVATION_PROLOG="public/buku/decoding-corporate-innovation/prolog/index.html"
readonly INNOVATION_CHAPTER_ONE="public/buku/decoding-corporate-innovation/bab-1-innovation-disconnect/index.html"
readonly INNOVATION_CHAPTER_TWO="public/buku/decoding-corporate-innovation/bab-2-rethinking-corporate-innovation/index.html"

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

assert_chart \
  "$INNOVATION_PROLOG" \
  "gci-indonesia-pillars" \
  "WEF Global Competitiveness Index 2019" \
  "6" \
  "Innovation capability" \
  ">38<" \
  "Market size" \
  ">82<"

assert_chart \
  "$INNOVATION_CHAPTER_ONE" \
  "bain-high-performer" \
  "Bain Innovation Assessment survey, 2012" \
  "22" \
  "High performer" \
  "Other" \
  ">13%<" \
  ">5%<" \
  ">23<" \
  ">−56<"

assert_chart \
  "$INNOVATION_CHAPTER_ONE" \
  "innovation-readiness" \
  "BCG Global Innovation Survey 2024; BCG analysis" \
  "25" \
  "Ready" \
  "Unready" \
  ">2024<" \
  ">3%<" \
  ">97%<"

assert_chart \
  "$INNOVATION_CHAPTER_ONE" \
  "innovation-priorities" \
  "BCG Global Innovation Survey 2024; BCG analysis" \
  "26" \
  "Top priority" \
  "Top-three priority" \
  ">2005<" \
  ">19%<" \
  ">47%<" \
  ">2024<" \
  ">35%<" \
  ">48%<" \
  ">83%<"

assert_chart \
  "$INNOVATION_CHAPTER_TWO" \
  "disruption-growth-potential" \
  "McKinsey & Company" \
  "39" \
  "Incremental changes" \
  "Fundamental disruption" \
  "Business as usual" \
  "Innovation" \
  "illustrative"

assert_source_data_details \
  "$INNOVATION_PROLOG" \
  "6" \
  "Innovation capability" \
  ">38<"

assert_source_data_details \
  "$INNOVATION_CHAPTER_ONE" \
  "22" \
  "High performer" \
  ">−56<"

assert_source_data_details \
  "$INNOVATION_CHAPTER_ONE" \
  "25" \
  "Ready" \
  ">3<" \
  ">97<"

assert_source_data_details \
  "$INNOVATION_CHAPTER_ONE" \
  "26" \
  "Top priority" \
  ">35<" \
  ">48<" \
  ">83<"

assert_source_data_details \
  "$INNOVATION_CHAPTER_TWO" \
  "39" \
  "Kondisi industri" \
  "Business as usual" \
  "Inovasi"

assert_compiled_css_matches '\.read-chart[[:space:]]*\{' "custom chart CSS"
assert_compiled_css_matches '\.dark[[:space:]]+\.read-chart' "dark-mode chart rule"

printf 'Site checks passed.\n'
