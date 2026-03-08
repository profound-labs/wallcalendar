#!/usr/bin/env python3
"""Compare compiled example calendar PDFs against their last committed versions.

Checks out the committed PDF, rebuilds it with make, splits multi-page PDFs into
individual pages, and uses ImageMagick 'compare' to detect pixel differences.

Usage:
    ./diff-cal.py                        # test all calendars from Makefile
    ./diff-cal.py --cal cal-plain        # test a single calendar (name or .pdf)
    ./diff-cal.py --cal cal-plain.pdf
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


DIFF_DIRS = ["diff-old", "diff-new", "diff-compare"]


def clean_diff_folders():
    for d in DIFF_DIRS:
        p = Path(d)
        p.mkdir(exist_ok=True)
        for f in p.iterdir():
            if f.name != ".gitkeep":
                f.unlink()
        gitkeep = p / ".gitkeep"
        gitkeep.touch()


def calendars_from_makefile():
    """Parse the Makefile to get the list of calendar base names."""
    makefile = Path("Makefile").read_text()

    cals = []

    # calendars: cal-translations cal-plain.pdf ...
    m = re.search(r"^calendars:\s*(.+)$", makefile, re.MULTILINE)
    if m:
        for token in m.group(1).split():
            if token.endswith(".pdf"):
                cals.append(token.removesuffix(".pdf"))
            elif token.startswith("cal-"):
                # inline target like cal-translations — expand it
                sub = re.search(
                    rf"^{re.escape(token)}:\s*(.+)$", makefile, re.MULTILINE
                )
                if sub:
                    for t in sub.group(1).split():
                        cals.append(t.removesuffix(".pdf"))

    return cals


def validate_calendar(name):
    """Check that a calendar target exists in the Makefile."""
    result = subprocess.run(
        ["make", "-qp", f"{name}.pdf"],
        capture_output=True,
        text=True,
    )
    pattern = rf"^{re.escape(name)}\.pdf:"
    if re.search(pattern, result.stdout, re.MULTILINE):
        return True
    return False


def get_page_count(pdf_path):
    result = subprocess.run(
        ["pdfinfo", str(pdf_path)], capture_output=True, text=True
    )
    for line in result.stdout.splitlines():
        if line.startswith("Pages:"):
            return int(line.split()[1])
    return 0


def burst_pdf(pdf_path, dest_dir, name):
    """Split a PDF into per-page files in dest_dir."""
    pages = get_page_count(pdf_path)
    if pages > 1:
        subprocess.run(
            ["pdftk", str(pdf_path), "burst", "output",
             str(Path(dest_dir) / f"{name}-%02d.pdf")],
            check=True,
            capture_output=True,
        )
    elif pdf_path.exists():
        shutil.copy2(pdf_path, Path(dest_dir) / f"{name}-01.pdf")


def restore_pdf(name):
    """Restore a PDF to its committed version, or remove if untracked."""
    pdf = f"{name}.pdf"
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", pdf],
        capture_output=True,
    )
    if result.returncode == 0:
        subprocess.run(["git", "checkout", pdf], capture_output=True)
    else:
        Path(pdf).unlink(missing_ok=True)


def compare_pages():
    """Compare old vs new page images, return (skipped, differ) lists."""
    differ = []
    missing = []

    old_dir = Path("diff-old")
    new_dir = Path("diff-new")
    cmp_dir = Path("diff-compare")

    for old_page in sorted(old_dir.glob("*.pdf")):
        new_page = new_dir / old_page.name
        if not new_page.exists():
            missing.append(f"{old_page.name} (missing from diff-new)")
            continue

        out_jpg = cmp_dir / f"{old_page.stem}.jpg"
        result = subprocess.run(
            ["compare", "-metric", "AE",
             str(old_page), str(new_page),
             "-compose", "src", "-alpha", "off",
             str(out_jpg)],
            capture_output=True,
            text=True,
        )
        # ImageMagick writes the metric to stderr
        metric = result.stderr.strip()
        ae_value = metric.split()[0] if metric else "0"
        if ae_value != "0":
            differ.append(f"{old_page.name}: {metric}")

    return missing, differ


def main():
    parser = argparse.ArgumentParser(
        description="Compare compiled calendar PDFs against committed versions."
    )
    parser.add_argument(
        "--cal",
        metavar="NAME",
        help="Calendar to test (base name or .pdf). Tests all if omitted.",
    )
    args = parser.parse_args()

    os.chdir(Path(__file__).resolve().parent)

    # Determine which calendars to process
    if args.cal:
        name = args.cal.removesuffix(".pdf")
        # Strip trailing page-number suffix like -1, -02
        name = re.sub(r"-\d{1,2}$", "", name)
        if not validate_calendar(name):
            print(f"Calendar '{name}' not found in Makefile", file=sys.stderr)
            sys.exit(1)
        cal_names = [name]
    else:
        cal_names = calendars_from_makefile()

    clean_diff_folders()

    skipped = []

    for name in cal_names:
        pdf = Path(f"{name}.pdf")
        print(f"Processing {name}... ", end="", flush=True)

        # Restore committed version and burst into old pages
        if pdf.exists():
            restore_pdf(name)
            burst_pdf(pdf, "diff-old", name)

        # Rebuild
        result = subprocess.run(
            ["make", str(pdf), "-B"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print("SKIPPED (build failed)")
            skipped.append(name)
            continue

        # Burst new build into new pages
        if pdf.exists():
            burst_pdf(pdf, "diff-new", name)

        print("done")

    # Compare
    missing, differ = compare_pages()

    # Restore all PDFs to committed versions
    print("Restoring PDFs to committed versions...")
    for name in cal_names:
        restore_pdf(name)

    # Report
    all_skipped = skipped + missing
    if all_skipped:
        print("\nSkipped:")
        for s in all_skipped:
            print(f"  - {s}")

    if differ:
        print("\nFiles with differences:")
        for d in differ:
            print(f"  - {d}")

    print("Done.")


if __name__ == "__main__":
    main()
