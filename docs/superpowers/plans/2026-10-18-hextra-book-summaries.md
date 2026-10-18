# Hextra Book Summaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create and deploy a reproducible Hextra documentation site for Indonesian book summaries.

**Architecture:** Hugo Modules supplies the pinned Hextra theme. Hugo's `buku` content section cascades Hextra's docs layout so its book directories and weighted chapter pages automatically become a nested sidebar.

**Tech Stack:** Hugo Extended 0.168.0, Go modules, Hextra 0.13.0, GitHub Actions, GitHub Pages

## Global Constraints

- Production URL is `https://thomasbudiarjo.github.io/read-summary/`.
- Book URLs use `/buku/<slug>/` and source files live under `content/buku/`.
- UI-facing and example text is Indonesian where natural.
- Push-to-`main` deployment uses GitHub Pages Actions.

---

### Task 1: Executable site acceptance check

**Files:**
- Create: `scripts/check-site.sh`

**Interfaces:**
- Consumes: Hugo CLI, source configuration, and rendered `public/` output.
- Produces: a nonzero exit for build/content/navigation failures and `Site checks passed.` on success.

- [ ] Write a Bash check that deletes `public/`, runs `hugo --gc --minify`, asserts the expected rendered pages, checks `/read-summary/` links, and checks the example chapter HTML for the parent and sibling labels.
- [ ] Run `bash scripts/check-site.sh`.
- [ ] Confirm it fails because the site has not been implemented.

### Task 2: Hugo, Hextra, and example content

**Files:**
- Create: `hugo.yaml`
- Create: `go.mod`
- Generate: `go.sum`
- Create: `content/_index.md`
- Create: `content/buku/_index.md`
- Create: `content/buku/contoh-buku/_index.md`
- Create: `content/buku/contoh-buku/bab-1-awal-perjalanan.md`
- Create: `content/buku/contoh-buku/bab-2-menghadapi-rintangan.md`
- Create: `content/buku/contoh-buku/bab-3-pelajaran-utama.md`

**Interfaces:**
- Consumes: Hextra v0.13.0 as a Hugo Module.
- Produces: `/`, `/buku/`, `/buku/contoh-buku/`, and three nested chapter pages with a docs sidebar.

- [ ] Configure title, exact production base URL, Hextra module import, Indonesian-facing menus, search, footer, and edit links.
- [ ] Add the root and `buku` section pages; set `cascade.type: docs` and normal forward pagination.
- [ ] Add a fictional example book and three clearly marked example summaries with sequential weights.
- [ ] Run `hugo mod tidy` to lock the module.
- [ ] Run `bash scripts/check-site.sh` and confirm it passes.

### Task 3: Authoring templates and documentation

**Files:**
- Create: `archetypes/buku.md`
- Create: `archetypes/bab.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: `hugo new content --kind buku|bab`.
- Produces: editable section/chapter Markdown and Indonesian author instructions.

- [ ] Add a book section archetype with title, order, open-sidebar setting, author prompt, and summary prompt.
- [ ] Add a chapter archetype with title, order, publication state, and structured summary prompts.
- [ ] Document prerequisites, local run/build commands, exact new-book/new-chapter commands, ordering, publishing, deployment, and Pages setup.
- [ ] Generate temporary content from both archetypes and confirm the resulting paths/front matter, then remove the temporary content.

### Task 4: GitHub Pages deployment

**Files:**
- Create: `.github/workflows/pages.yaml`

**Interfaces:**
- Consumes: pushes to `main` or manual workflow dispatch.
- Produces: a Pages artifact built with `${{ steps.pages.outputs.base_url }}/` and a deployed Pages release.

- [ ] Add least-privilege Pages permissions, deployment concurrency, latest stable major versions of official Actions, Go setup, pinned Hugo Extended installation, module download, production build, artifact upload, and deploy job.
- [ ] Parse the workflow as YAML and check key deployment fields.
- [ ] Run `bash scripts/check-site.sh` again.

### Task 5: Delivery

**Files:**
- Review all files above.

**Interfaces:**
- Consumes: verified working tree.
- Produces: committed and pushed feature branch plus a draft pull request to `main`.

- [ ] Review the requirement checklist and `git diff --check`.
- [ ] Commit logical changes with descriptive messages.
- [ ] Push `cursor/setup-hextra-book-summaries-50d6`.
- [ ] Open a pull request describing implementation choices, verification, content authoring, and the one-time Pages setting.
