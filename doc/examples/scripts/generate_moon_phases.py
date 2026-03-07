#!/usr/bin/env python3
"""Generate astronomically accurate moon phase data in wallcalendar events.csv format.

Uses the PyEphem library for astronomical calculations.

Usage:
    poetry run python generate_moon_phases.py YEAR [OUTPUT_FILE]

Examples:
    poetry run python generate_moon_phases.py 2026
    poetry run python generate_moon_phases.py 2026 ../data/moonphases-2026.csv
"""

import sys
from datetime import date
import ephem


PHASE_MAP = {
    "new_moon": ("\\NewMoon", ephem.next_new_moon),
    "first_quarter": ("\\FirstQuarter", ephem.next_first_quarter_moon),
    "full_moon": ("\\FullMoon", ephem.next_full_moon),
    "last_quarter": ("\\LastQuarter", ephem.next_last_quarter_moon),
}


def compute_moon_phases(year: int) -> list[tuple[date, str]]:
    """Compute all moon phases for the given year.

    Returns a sorted list of (date, latex_command) tuples.
    """
    results = []

    # Start searching from a few days before the year begins,
    # in case a phase falls on Jan 1.
    search_start = ephem.Date(f"{year}/1/1") - 2

    for _, (latex_cmd, next_phase_fn) in PHASE_MAP.items():
        d = search_start
        while True:
            phase_date = next_phase_fn(d)
            py_date = ephem.Date(phase_date).datetime().date()
            if py_date.year > year:
                break
            if py_date.year == year:
                results.append((py_date, latex_cmd))
            d = phase_date + 1  # advance past this phase to find the next one

    results.sort(key=lambda x: x[0])
    return results


def write_csv(phases: list[tuple[date, str]], output_file: str) -> None:
    with open(output_file, "w") as f:
        f.write("date;day_text;footnote\n")
        for d, cmd in phases:
            f.write(f"{d.isoformat()};{cmd};\n")


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} YEAR [OUTPUT_FILE]", file=sys.stderr)
        sys.exit(1)

    year = int(sys.argv[1])
    output_file = sys.argv[2] if len(sys.argv) > 2 else f"moonphases-{year}.csv"

    phases = compute_moon_phases(year)
    write_csv(phases, output_file)
    print(f"Wrote {len(phases)} moon phases for {year} to {output_file}")


if __name__ == "__main__":
    main()
