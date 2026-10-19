# Native Book Charts Design

## Goal

Recreate the unambiguous figures in *Decoding Corporate Innovation* as responsive, accessible, theme-aware web charts without embedding page scans or inventing values.

## Approaches considered

1. **Hugo-rendered semantic HTML/CSS charts (chosen).** No runtime dependency, no CDN, automatic light/dark styling, and readable markup. It fits the book's bar, stacked-bar, and qualitative comparison figures.
2. **Self-hosted Chart.js.** More interactive and broadly reusable, but adds a large JavaScript payload, canvas accessibility work, and theme-change synchronization.
3. **Build-time SVG.** Precise and dependency-free, but significantly more template arithmetic and less natural mobile reflow for long Indonesian labels.

## Architecture

- `layouts/shortcodes/chart.html` loads one chart by ID from `data/charts/`.
- Focused chart partials render three reusable forms:
  - horizontal bars;
  - grouped metric comparisons, including negative values;
  - 100% stacked bars;
  - a qualitative arc comparison for the non-numeric disruption figure.
- `assets/css/custom.css` provides responsive layout, accessible contrast, and Hextra-compatible `.dark` overrides.
- Each YAML file owns the title, caption, source, printed page, legend, scale, and original values for one figure.
- The shortcode emits a semantic `<figure>` with an accessible heading/description and a source caption.

## Figure fidelity

Recreate:

1. **Printed p. 6:** GCI Indonesia pillar scores. Plot only the printed 0–100 scores; retain the visible note that the marker legend is unreadable.
2. **Printed p. 22:** Bain high-performer comparison. Preserve the four printed metrics and their own scales, including eNPS `23` versus `−56`.
3. **Printed p. 25:** innovation readiness, 2021–2024 (`Ready`/`Unready`).
4. **Printed p. 26:** innovation priority, 2005–2024 (`Top priority` and other `Top-three priority` values).
5. **Printed p. 39:** qualitative incremental-change versus fundamental-disruption comparison. It displays no numeric scale, so render only the original relative/uncertainty concept and label it illustrative.

Skip:

- **Printed p. 4:** scatter-point coordinates and income-group assignments are not recoverable reliably, and the printed axis labels conflict with their scales.
- **Printed p. 20:** the source does not print the time-series values and the page carries a mismatched caption.
- **Printed p. 24:** absolute line-series values are not printed and the meaning of percentage labels is not explained.

The existing `[tidak jelas]` notes stay visible. No reading prose changes beyond inserting chart shortcodes and moving the existing source tables into collapsed details blocks immediately below their charts.

## Verification

- Extend `scripts/check-site.sh` before implementation to require all five figures, captions, data-table details, and compiled dark-mode chart CSS.
- Run `hugo --gc --minify` and the full acceptance script.
- Inspect rendered values and table preservation.
- Manually test desktop and mobile layouts in light and dark modes.
- Save representative light and dark screenshots as walkthrough artifacts.
