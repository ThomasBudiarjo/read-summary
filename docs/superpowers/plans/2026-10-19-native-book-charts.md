# Native Book Charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reusable, dependency-free Hugo charts for five unambiguous figures in *Decoding Corporate Innovation*.

**Architecture:** A `chart` shortcode resolves chart definitions from `data/charts/*.yaml` and delegates to focused semantic HTML partials. Project custom CSS handles visualization, mobile reflow, and Hextra light/dark themes; existing Markdown tables remain in collapsed details blocks.

**Tech Stack:** Hugo 0.168.0, Hextra 0.13.0, Hugo templates, YAML data, CSS

## Global Constraints

- Never embed PDF screenshots or cropped page images.
- Never display a numeric value that is not printed unambiguously in the book.
- Do not rewrite the reading prose or remove existing `[tidak jelas]` notes.
- Caption every chart with original figure/source wording and printed page number.
- Keep the source data table under each chart in a collapsed details block.
- Reusable chart data lives outside the shortcode implementation.

---

### Task 1: Rendered-output acceptance checks

**Files:**
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: generated HTML/CSS in `public/`.
- Produces: targeted failures for missing chart IDs, captions, source-table details, values, or dark-mode CSS.

- [ ] Add checks for the five chart IDs on their expected pages.
- [ ] Check source/page captions, preserved data-table details, representative values, semantic `<figure>` markup, and compiled `.dark` chart styles.
- [ ] Run `bash scripts/check-site.sh` and confirm failure because charts do not exist.
- [ ] Commit the red acceptance checks.

### Task 2: Reusable chart system

**Files:**
- Create: `layouts/shortcodes/chart.html`
- Create: `layouts/partials/charts/bar.html`
- Create: `layouts/partials/charts/metrics.html`
- Create: `layouts/partials/charts/stacked.html`
- Create: `layouts/partials/charts/arcs.html`
- Create: `assets/css/custom.css`

**Interfaces:**
- Consumes: positional chart ID and `site.Data.charts`.
- Produces: accessible `<figure class="read-chart">` markup with one visualization partial and caption.

- [ ] Validate missing/unknown chart IDs and chart types with Hugo build errors.
- [ ] Render semantic labels and visible values for all chart types.
- [ ] Add responsive CSS with no horizontal page overflow and explicit `.dark` variables.
- [ ] Run a focused fixture build against one chart of each type.

### Task 3: Figure data and content placement

**Files:**
- Create: five files under `data/charts/`.
- Modify: `content/buku/decoding-corporate-innovation/prolog.md`.
- Modify: `content/buku/decoding-corporate-innovation/bab-1-innovation-disconnect.md`.
- Modify: `content/buku/decoding-corporate-innovation/bab-2-rethinking-corporate-innovation.md`.

**Interfaces:**
- Consumes: printed values verified from the attached PDF.
- Produces: p. 6, 22, 25, 26, and 39 charts at the matching reading locations.

- [ ] Encode only source values enumerated in the design.
- [ ] Insert each chart next to its existing source table.
- [ ] Wrap each existing source table in a closed Hextra details block without changing table text.
- [ ] Keep all uncertainty notes visible outside the collapsed data blocks.
- [ ] Run `hugo --gc --minify` and `bash scripts/check-site.sh`.

### Task 4: Author documentation

**Files:**
- Modify: `README.md`.

**Interfaces:**
- Consumes: shortcode and YAML schema.
- Produces: a concise copyable example for future books.

- [ ] Document the shortcode call, required YAML fields, supported types, source/page captions, table fallback, and fidelity rule.

### Task 5: Visual and delivery verification

**Files:**
- Review all files above.

**Interfaces:**
- Consumes: local Hugo server and completed branch.
- Produces: light/dark artifacts and a non-draft pull request.

- [ ] Test representative charts at desktop and mobile widths in both themes.
- [ ] Capture at least one light screenshot and one dark screenshot covering multiple charts.
- [ ] Run final Hugo build, acceptance checks, source-data audit, and `git diff --check`.
- [ ] Review the complete diff, commit logical changes, push, and open a non-draft PR to `main`.
