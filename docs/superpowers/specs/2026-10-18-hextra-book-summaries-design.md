# Hextra Book Summaries Design

## Goal

Build a Hugo site named **Read Summary** for Indonesian-language book notes, deployed at `https://thomasbudiarjo.github.io/read-summary/`.

## Chosen approach

Use Hextra through Hugo Modules, the integration recommended by Hextra. Pin Hextra v0.13.0 in `go.mod`/`go.sum` for reproducible builds. This is simpler than a Git submodule and keeps theme source out of the repository; vendoring the theme would add unnecessary maintenance.

## Content and navigation

- `content/_index.md` is a landing page that links to the book collection and example book.
- `content/buku/_index.md` defines `/buku/` as a Hextra docs-style section by cascading `type: docs`.
- Every book is a section at `content/buku/<slug>/_index.md`, producing `/buku/<slug>/`.
- Chapter summaries are weighted Markdown pages inside that book directory.
- Hextra derives the sidebar hierarchy and breadcrumbs from this directory structure. Book sections are open by default.
- One clearly labeled fictional example book contains three example chapter summaries.

## Authoring

`archetypes/buku.md` and `archetypes/bab.md` provide front matter and prompts for new books and chapters. The README gives exact `hugo new content --kind ...` commands, explains weights and drafts, and documents local preview.

## Build and deployment

The project configuration sets the canonical project Pages base URL. A GitHub Actions workflow runs on pushes to `main`, installs a pinned Hugo Extended release, resolves the Hugo module, builds with the Pages-provided base URL, uploads `public/`, and deploys through GitHub Pages.

## Verification

A repository script builds the production site and checks:

- the home, book index, example book, and three chapter pages exist;
- generated links include the `/read-summary/` project prefix;
- a rendered chapter page contains links for its parent book and sibling chapters, demonstrating the expected sidebar hierarchy.

The owner must enable **Settings → Pages → Build and deployment → Source: GitHub Actions** once.
