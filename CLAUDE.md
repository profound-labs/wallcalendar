# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`wallcalendar` is a LaTeX document class for creating wall calendars. It requires **LuaLaTeX** as the engine. The class builds on `memoir` and uses TikZ for calendar rendering, with Lua scripts for CSV parsing and date calculations.

## Build Commands

```bash
# Compile an example calendar
cd doc/examples
lualatex -interaction=nonstopmode -halt-on-error cal-plain.tex

# Build the class file from literate source (requires Emacs org-mode)
make wallcalendar.cls

# Build user manual
make wallcalendar.pdf

# Package for CTAN
make ctan

# Install as local TeX package
make local-install
```

## Architecture

### Core Files

- **`wallcalendar.cls`** (~2600 lines) — The document class. Defines layouts, page geometry, TikZ calendar styles, formatting hooks, and the `\MonthPage` command.
- **`wallcalendar-date.lua`** — Date arithmetic (Julian day conversions, moon phase calculations).
- **`wallcalendar-csv.lua`** — Parses CSV event files for calendar marks.
- **`wallcalendar-helpers.lua`** — Utility functions used by the other Lua modules.

### Layout System

Layouts are registered via pgfkeys under `/MonthPage/layout handlers/`:
- `full page` — Photo fills the page, calendar days overlaid with opacity
- `small landscape` — Small landscape photo above a calendar grid (default)
- `photo and notes` — Photo and calendar on separate facing pages
- `large calendar` — Calendar grid without photo

Each layout has a corresponding format command (e.g., `\fullPageFmt`, `\photoAndNotesFmt`) containing hooks like `\monthFmt`, `\yearFmt`, `\dayTextFmt` that users redefine in their preamble.

Special layouts (`\YearPlannerPage`, `\ThumbnailsPage`, `\VarnishMaskPage`) are standalone commands, not part of the `\MonthPage` dispatch.

### Internationalization

Translation files live in `i18n/wallcalendar-<language>.tex`. They define day letter abbreviations and month names. The `language` class option auto-loads the matching file. Custom translations can be provided via the `translationsInputFile` option.

### Event Marks

Events are loaded from CSV files specified by the `eventsCsv` class option. The Lua CSV parser (`wallcalendar-csv.lua`) reads event data, and marks are rendered as TikZ decorations on calendar days.

## Testing

The example documents in `doc/examples/` serve as integration tests. Re-rendering them verifies that the class, layouts, Lua scripts, and CSV parsing all work end-to-end.

```bash
cd doc/examples
make calendars
```

This compiles all example `.tex` files with LuaLaTeX. A successful build (all PDFs produced without errors) confirms the package is working correctly. Any LaTeX or Lua error during compilation indicates a regression.

### Visual Regression Testing

`doc/examples/diff-cal.py` compares example calendar PDFs between two versions of the library. It splits multi-page PDFs into per-page files and uses ImageMagick `compare` to detect pixel differences. For rebuild-from-commit modes it uses `git worktree` to build in an isolated checkout.

```bash
cd doc/examples

# Default: committed PDFs (old) vs rebuild from working tree (new)
./diff-cal.py
./diff-cal.py --cal cal-plain            # single calendar

# Old PDFs from a specific commit, new from working tree rebuild
./diff-cal.py --old-commit-pdf abc123

# Rebuild old from library state at a commit, new from working tree
./diff-cal.py --old-commit-pdf-rebuild abc123

# Rebuild both old and new from specific commits
./diff-cal.py --old-commit-pdf-rebuild abc123 --new-commit-pdf-rebuild def456
```

Requires: `pdfinfo`, `pdftk`, ImageMagick `compare`.

## Examples

All examples are in `doc/examples/`. Key ones:
- `cal-plain.tex` — Basic small landscape layout
- `cal-photo-and-notes.tex` — Two-page photo+notes layout
- `cal-marks.tex` — CSV event marks
- `cal-year-planner.tex` / `cal-year-planner-compact.tex` — Year planner layouts
- `frog-*.tex` — Translation examples (English, Japanese, Hungarian)
