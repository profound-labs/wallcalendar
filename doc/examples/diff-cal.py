#!/usr/bin/env python3
"""Compare example calendar PDFs between two versions of the library.

Modes of operation:

  ./diff-cal.py
      Old: committed PDFs (HEAD). New: rebuild from working tree.

  ./diff-cal.py --cal cal-showframe
      Same, but only for one calendar.

  ./diff-cal.py --old-commit-pdf <hash>
      Old: PDFs from the given commit. New: rebuild from working tree.

  ./diff-cal.py --old-commit-pdf-rebuild <hash>
      Old: rebuild from library state at <hash>. New: rebuild from working tree.

  ./diff-cal.py --old-commit-pdf-rebuild <hash> --new-commit-pdf-rebuild <hash>
      Old: rebuild from first hash. New: rebuild from second hash.

Saving and reusing PDFs:

  ./diff-cal.py --old-commit-pdf <hash> --old-pdf-save-to-folder <path>
      Save old burst pages to <path> for later reuse.

  ./diff-cal.py --old-commit-pdf-rebuild <hash> --old-pdf-save-to-folder <path>
      Rebuild old PDFs and save burst pages to <path>.

  ./diff-cal.py --old-commit-pdf-rebuild <hash> --old-pdf-save-to-folder <path> \\
                --new-commit-pdf-rebuild <hash> --new-pdf-save-to-folder <path>
      Rebuild both and save burst pages.

  ./diff-cal.py --old-commit-pdf-rebuild <hash> --old-worktree-path <path>
      Rebuild old PDFs and keep the worktree at <path> for inspection.

  ./diff-cal.py --old-commit-pdf-rebuild <hash> --old-worktree-path <path> \\
                --new-commit-pdf-rebuild <hash> --new-worktree-path <path>
      Rebuild both and keep both worktrees.

  ./diff-cal.py --old-pdf-from-folder <path>
      Use previously saved burst pages as old PDFs.

  ./diff-cal.py --new-pdf-from-folder <path>
      Use previously saved burst pages as new PDFs.

All flags can be combined with --cal to limit to a single calendar.
"""

import argparse
import atexit
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


DIFF_DIRS = ["diff-old", "diff-new", "diff-compare"]

# Resolved once in main(), used by worktree helpers.
REPO_ROOT: Path | None = None
EXAMPLES_REL: str | None = None


def clean_diff_folders():
    for d in DIFF_DIRS:
        p = Path(d)
        p.mkdir(exist_ok=True)
        for f in p.iterdir():
            if f.name != ".gitkeep":
                f.unlink()
        (p / ".gitkeep").touch()


# ---------------------------------------------------------------------------
# Makefile parsing
# ---------------------------------------------------------------------------

def calendars_from_makefile(makefile_path="Makefile"):
    """Parse a Makefile to get the list of calendar base names."""
    makefile = Path(makefile_path).read_text()
    cals = []
    m = re.search(r"^calendars:\s*(.+)$", makefile, re.MULTILINE)
    if m:
        for token in m.group(1).split():
            if token.endswith(".pdf"):
                cals.append(token.removesuffix(".pdf"))
            elif token.startswith("cal-"):
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
        capture_output=True, text=True,
    )
    return bool(re.search(rf"^{re.escape(name)}\.pdf:", result.stdout, re.MULTILINE))


# ---------------------------------------------------------------------------
# PDF helpers
# ---------------------------------------------------------------------------

def get_page_count(pdf_path):
    result = subprocess.run(
        ["pdfinfo", str(pdf_path)], capture_output=True, text=True,
    )
    for line in result.stdout.splitlines():
        if line.startswith("Pages:"):
            return int(line.split()[1])
    return 0


def burst_pdf(pdf_path, dest_dir, name):
    """Split a PDF into per-page files in dest_dir."""
    pdf_path = Path(pdf_path)
    if not pdf_path.exists():
        return
    pages = get_page_count(pdf_path)
    if pages > 1:
        subprocess.run(
            ["pdftk", str(pdf_path), "burst", "output",
             str(Path(dest_dir) / f"{name}-%02d.pdf")],
            check=True, capture_output=True,
        )
    else:
        shutil.copy2(pdf_path, Path(dest_dir) / f"{name}-01.pdf")


def restore_pdf(name):
    """Restore a PDF to its committed version, or remove if untracked."""
    pdf = f"{name}.pdf"
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", pdf], capture_output=True,
    )
    if result.returncode == 0:
        subprocess.run(["git", "checkout", pdf], capture_output=True)
    else:
        Path(pdf).unlink(missing_ok=True)


# ---------------------------------------------------------------------------
# Git worktree helpers
# ---------------------------------------------------------------------------

def worktree_add(commit_hash, worktree_path=None):
    """Create a detached worktree for commit_hash, return its Path.

    If worktree_path is given, the worktree is created there and NOT cleaned
    up on exit.  Otherwise a temporary directory is used and registered for
    automatic cleanup via atexit.
    """
    if worktree_path:
        wt = str(Path(worktree_path).resolve())
        subprocess.run(
            ["git", "-C", str(REPO_ROOT), "worktree", "add",
             "--detach", wt, commit_hash],
            check=True, capture_output=True, text=True,
        )
        return Path(wt)
    tmp = tempfile.mkdtemp(prefix="diffcal-wt-")
    subprocess.run(
        ["git", "-C", str(REPO_ROOT), "worktree", "add",
         "--detach", tmp, commit_hash],
        check=True, capture_output=True, text=True,
    )
    atexit.register(worktree_remove, tmp)
    return Path(tmp)


def worktree_remove(path):
    """Remove a git worktree (best-effort)."""
    subprocess.run(
        ["git", "-C", str(REPO_ROOT), "worktree", "remove", "--force", str(path)],
        capture_output=True,
    )
    # Belt-and-suspenders in case worktree remove didn't clean up.
    shutil.rmtree(path, ignore_errors=True)


def build_in_worktree(worktree_path, cal_names):
    """Build calendars inside a worktree. Returns {name: pdf_path} for successes
    and a list of skipped names."""
    examples_dir = worktree_path / EXAMPLES_REL
    built = {}
    skipped = []
    for name in cal_names:
        pdf = examples_dir / f"{name}.pdf"
        result = subprocess.run(
            ["make", str(pdf.name), "-B"],
            cwd=str(examples_dir),
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            skipped.append(name)
        elif pdf.exists():
            built[name] = pdf
    return built, skipped


# ---------------------------------------------------------------------------
# Strategies for obtaining old / new PDFs
# ---------------------------------------------------------------------------

def get_old_committed(cal_names, dest_dir, commit=None):
    """Get old PDFs from a git commit (default HEAD) and burst into dest_dir.

    Returns list of names that were skipped (not found at that commit).
    """
    skipped = []
    for name in cal_names:
        pdf_name = f"{name}.pdf"

        if commit:
            # Extract PDF from a specific commit.
            ref = f"{commit}:{EXAMPLES_REL}/{pdf_name}"
            result = subprocess.run(
                ["git", "-C", str(REPO_ROOT), "show", ref],
                capture_output=True,
            )
            if result.returncode != 0:
                skipped.append(f"{name} (not found at {commit})")
                continue
            pdf_path = Path(pdf_name)
            pdf_path.write_bytes(result.stdout)
        else:
            # Restore the working-tree copy to HEAD.
            restore_pdf(name)
            pdf_path = Path(pdf_name)
            if not pdf_path.exists():
                skipped.append(f"{name} (not committed)")
                continue

        burst_pdf(pdf_path, dest_dir, name)
    return skipped


def get_rebuilt(dest_dir, commit_hash, cal_filter=None, worktree_path=None):
    """Rebuild calendars from a specific commit using a worktree, burst into dest_dir.

    The calendar list is read from the worktree's own Makefile so that only
    targets that actually exist at that commit are attempted.

    cal_filter:    if set, only build this single calendar (must exist in the
                   worktree Makefile).
    worktree_path: if set, create the worktree at this path and keep it after
                   the script exits.

    Returns (built_names, skipped_names).
    """
    print(f"  Creating worktree for {commit_hash[:10]}...")
    wt = worktree_add(commit_hash, worktree_path=worktree_path)
    assert EXAMPLES_REL is not None
    wt_makefile = wt / EXAMPLES_REL / "Makefile"
    wt_cals = calendars_from_makefile(str(wt_makefile))
    if cal_filter:
        if cal_filter in wt_cals:
            wt_cals = [cal_filter]
        else:
            return [], [f"{cal_filter} (not in Makefile at {commit_hash[:10]})"]
    built, skipped = build_in_worktree(wt, wt_cals)
    for name, pdf_path in built.items():
        burst_pdf(pdf_path, dest_dir, name)
    return list(built.keys()), skipped


def get_new_from_working_tree(cal_names, dest_dir):
    """Rebuild calendars from the current working tree, burst into dest_dir.

    Returns list of skipped names.
    """
    skipped = []
    for name in cal_names:
        pdf = Path(f"{name}.pdf")
        result = subprocess.run(
            ["make", str(pdf), "-B"],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            skipped.append(name)
            continue
        if pdf.exists():
            burst_pdf(pdf, dest_dir, name)
    return skipped


# ---------------------------------------------------------------------------
# Save / load burst pages
# ---------------------------------------------------------------------------

def save_to_folder(diff_dir, dest_folder):
    """Copy burst page PDFs from diff_dir to dest_folder."""
    dest = Path(dest_folder)
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    for f in sorted(Path(diff_dir).glob("*.pdf")):
        shutil.copy2(f, dest / f.name)
        count += 1
    print(f"  Saved {count} page(s) to {dest}")


def load_from_folder(src_folder, diff_dir):
    """Copy burst page PDFs from src_folder into diff_dir.

    Returns list of problems (empty on success).
    """
    src = Path(src_folder)
    if not src.is_dir():
        print(f"  Folder not found: {src}", file=sys.stderr)
        return [f"folder not found: {src}"]
    pdfs = sorted(src.glob("*.pdf"))
    if not pdfs:
        print(f"  No PDFs found in {src}", file=sys.stderr)
        return [f"no PDFs in {src}"]
    for f in pdfs:
        shutil.copy2(f, Path(diff_dir) / f.name)
    print(f"  Loaded {len(pdfs)} page(s) from {src}")
    return []


# ---------------------------------------------------------------------------
# Comparison
# ---------------------------------------------------------------------------

def compare_pages():
    """Compare old vs new page images. Returns (missing, differ) lists."""
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
            ["compare", "-density", "150",
             "-metric", "AE",
             str(old_page), str(new_page),
             "-compose", "src", "-alpha", "off",
             str(out_jpg)],
            capture_output=True, text=True,
        )
        metric = result.stderr.strip()
        ae_value = metric.split()[0] if metric else "0"
        if ae_value != "0":
            differ.append(f"{old_page.name}: {metric}")

    return missing, differ


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    global REPO_ROOT, EXAMPLES_REL

    parser = argparse.ArgumentParser(
        description="Compare example calendar PDFs between two versions.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--cal", metavar="NAME",
        help="Calendar to test (base name or .pdf). Tests all if omitted.",
    )

    old_group = parser.add_mutually_exclusive_group()
    old_group.add_argument(
        "--old-commit-pdf", metavar="HASH",
        help="Use the committed PDF from this git commit as the old version.",
    )
    old_group.add_argument(
        "--old-commit-pdf-rebuild", metavar="HASH",
        help="Rebuild the old PDF from the library state at this git commit.",
    )
    old_group.add_argument(
        "--old-pdf-from-folder", metavar="PATH",
        help="Use previously saved burst pages from this folder as old PDFs.",
    )

    new_group = parser.add_mutually_exclusive_group()
    new_group.add_argument(
        "--new-commit-pdf-rebuild", metavar="HASH",
        help="Rebuild the new PDF from the library state at this git commit "
             "(default: rebuild from working tree).",
    )
    new_group.add_argument(
        "--new-pdf-from-folder", metavar="PATH",
        help="Use previously saved burst pages from this folder as new PDFs.",
    )

    parser.add_argument(
        "--old-pdf-save-to-folder", metavar="PATH",
        help="Save old burst pages to this folder for later reuse.",
    )
    parser.add_argument(
        "--new-pdf-save-to-folder", metavar="PATH",
        help="Save new burst pages to this folder for later reuse.",
    )
    parser.add_argument(
        "--old-worktree-path", metavar="PATH",
        help="Create the old worktree at this path and keep it after exit "
             "(requires --old-commit-pdf-rebuild).",
    )
    parser.add_argument(
        "--new-worktree-path", metavar="PATH",
        help="Create the new worktree at this path and keep it after exit "
             "(requires --new-commit-pdf-rebuild).",
    )

    args = parser.parse_args()

    if args.new_commit_pdf_rebuild and not args.old_commit_pdf_rebuild:
        parser.error(
            "--new-commit-pdf-rebuild requires --old-commit-pdf-rebuild"
        )

    if args.old_pdf_from_folder and args.old_pdf_save_to_folder:
        parser.error(
            "--old-pdf-from-folder and --old-pdf-save-to-folder are "
            "mutually exclusive"
        )

    if args.new_pdf_from_folder and args.new_pdf_save_to_folder:
        parser.error(
            "--new-pdf-from-folder and --new-pdf-save-to-folder are "
            "mutually exclusive"
        )

    if args.old_worktree_path and not args.old_commit_pdf_rebuild:
        parser.error(
            "--old-worktree-path requires --old-commit-pdf-rebuild"
        )

    if args.new_worktree_path and not args.new_commit_pdf_rebuild:
        parser.error(
            "--new-worktree-path requires --new-commit-pdf-rebuild"
        )

    # Resolve paths.
    examples_dir = Path(__file__).resolve().parent
    os.chdir(examples_dir)
    REPO_ROOT = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    )
    EXAMPLES_REL = str(examples_dir.relative_to(REPO_ROOT))

    # Determine which calendars to process.
    # For rebuild-from-commit modes the worktree's Makefile is used instead,
    # but we still need cal_names for non-rebuild paths and --cal validation.
    cal_filter = None
    both_rebuild = args.old_commit_pdf_rebuild and args.new_commit_pdf_rebuild
    if args.cal:
        name = args.cal.removesuffix(".pdf")
        name = re.sub(r"-\d{1,2}$", "", name)
        cal_filter = name
        # Skip current-Makefile validation when both sides rebuild from
        # commits — the target may not exist in the current tree.
        if not both_rebuild and not validate_calendar(name):
            print(f"Calendar '{name}' not found in Makefile", file=sys.stderr)
            sys.exit(1)
        cal_names = [name]
    else:
        cal_names = calendars_from_makefile()

    clean_diff_folders()

    skipped = []

    # --- Old version ---
    print("Preparing old PDFs...")
    if args.old_pdf_from_folder:
        sk = load_from_folder(args.old_pdf_from_folder, "diff-old")
        skipped.extend(sk)
    elif args.old_commit_pdf_rebuild:
        built, sk = get_rebuilt("diff-old", args.old_commit_pdf_rebuild,
                                cal_filter=cal_filter,
                                worktree_path=args.old_worktree_path)
        for name in built:
            print(f"  {name}: done")
        for name in sk:
            print(f"  {name}: SKIPPED (build failed)")
        skipped.extend(sk)
    elif args.old_commit_pdf:
        for name in cal_names:
            print(f"  {name}... ", end="", flush=True)
        sk = get_old_committed(cal_names, "diff-old", commit=args.old_commit_pdf)
        for name in cal_names:
            found = not any(name in s for s in sk)
            status = "done" if found else "SKIPPED"
            print(f"  {name}: {status}")
        skipped.extend(sk)
    else:
        sk = get_old_committed(cal_names, "diff-old")
        skipped.extend(sk)

    if args.old_pdf_save_to_folder:
        save_to_folder("diff-old", args.old_pdf_save_to_folder)

    # --- New version ---
    print("Preparing new PDFs...")
    if args.new_pdf_from_folder:
        sk = load_from_folder(args.new_pdf_from_folder, "diff-new")
        skipped.extend(sk)
    elif args.new_commit_pdf_rebuild:
        built, sk = get_rebuilt("diff-new", args.new_commit_pdf_rebuild,
                                cal_filter=cal_filter,
                                worktree_path=args.new_worktree_path)
        for name in built:
            print(f"  {name}: done")
        for name in sk:
            print(f"  {name}: SKIPPED (build failed)")
        skipped.extend(sk)
    else:
        for name in cal_names:
            print(f"  {name}... ", end="", flush=True)
            pdf = Path(f"{name}.pdf")
            result = subprocess.run(
                ["make", str(pdf), "-B"],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                print("SKIPPED (build failed)")
                skipped.append(name)
                continue
            if pdf.exists():
                burst_pdf(pdf, "diff-new", name)
            print("done")

    if args.new_pdf_save_to_folder:
        save_to_folder("diff-new", args.new_pdf_save_to_folder)

    # --- Compare ---
    print("Comparing...")
    missing, differ = compare_pages()

    # Restore working-tree PDFs to committed versions.
    if not args.new_commit_pdf_rebuild and not args.new_pdf_from_folder:
        print("Restoring PDFs to committed versions...")
        for name in cal_names:
            restore_pdf(name)

    # Also restore any PDFs we overwrote for --old-commit-pdf.
    if args.old_commit_pdf:
        for name in cal_names:
            restore_pdf(name)

    # --- Report ---
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
