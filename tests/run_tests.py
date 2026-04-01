#!/usr/bin/env python3
"""
Test runner for lib/nodes.typ.

For each tests/<name>.typ file:
  - Compile it to a PNG with `typst compile --root <repo-root>`
  - Compare the PNG to tests/ref/<name>.png using exact pixel matching
  - If no reference exists: save the output as the reference (CREATED)
  - If the images match: PASS
  - If they differ: FAIL (resulting image is saved next to the output)

Usage:
  python3 tests/run_tests.py [--update] [test-name ...]

Options:
  --update          Overwrite existing reference PNGs with new output
  test-name ...     Run only the named tests (without .typ extension)

Exit code: 0 if all tests pass, 1 if any test fails.
"""

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageChops
except ImportError:
    print("ERROR: Pillow is required. Install it with: pip install Pillow")
    sys.exit(1)


REPO_ROOT = Path(__file__).resolve().parent.parent
TESTS_DIR = REPO_ROOT / "tests"
REF_DIR = TESTS_DIR / "ref"


def compile_typ(typ_path: Path, png_path: Path) -> tuple[bool, str]:
    """Compile a .typ file to PNG. Returns (success, error_message)."""
    result = subprocess.run(
        [
            "typst", "compile",
            "--root", str(REPO_ROOT),
            str(typ_path),
            str(png_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return False, (result.stderr or result.stdout).strip()
    return True, ""


def images_equal(path_a: Path, path_b: Path) -> bool:
    """Return True if both PNG files are pixel-identical."""
    img_a = Image.open(path_a).convert("RGBA")
    img_b = Image.open(path_b).convert("RGBA")
    if img_a.size != img_b.size:
        return False
    diff = ImageChops.difference(img_a, img_b)
    # getbbox() on an RGBA image only looks at the alpha channel, so it returns
    # None even when R/G/B channels differ (alpha diff == 0 → bbox is None).
    # Check each channel independently instead.
    return all(ch.getbbox() is None for ch in diff.split())


def run_tests(names: list[str], update: bool) -> int:
    REF_DIR.mkdir(parents=True, exist_ok=True)

    # Discover tests
    if names:
        typ_files = []
        for name in names:
            p = TESTS_DIR / f"{name}.typ"
            if not p.exists():
                print(f"ERROR: test file not found: {p}")
                return 1
            typ_files.append(p)
    else:
        typ_files = sorted(TESTS_DIR.glob("*.typ"))

    if not typ_files:
        print("No test files found.")
        return 0

    passed = 0
    failed = 0
    created = 0

    with tempfile.TemporaryDirectory() as tmpdir:
        for typ_path in typ_files:
            name = typ_path.stem
            ref_path = REF_DIR / f"{name}.png"
            out_path = Path(tmpdir) / f"{name}.png"
            failed_path = TESTS_DIR / f"{name}.failed.png"

            # Compile
            ok, err = compile_typ(typ_path, out_path)
            if not ok:
                print(f"[ERROR] {name}: typst compile failed\n        {err}")
                failed += 1
                continue

            if update and ref_path.exists():
                # --update: overwrite reference unconditionally
                shutil.copy2(out_path, ref_path)
                print(f"[UPDATED] {name}")
                passed += 1
                continue

            if not ref_path.exists():
                # First run: save as reference
                shutil.copy2(out_path, ref_path)
                print(f"[CREATED] {name}  →  {ref_path.relative_to(REPO_ROOT)}")
                created += 1
                continue

            # Compare
            if images_equal(out_path, ref_path):
                print(f"[PASS]    {name}")
                passed += 1
            else:
                shutil.copy2(out_path, failed_path)
                print(
                    f"[FAIL]    {name}  (resulting image saved to "
                    f"{failed_path.relative_to(REPO_ROOT)})"
                )
                failed += 1

    total = passed + failed + created
    print(f"\n{total} test(s): {passed} passed, {created} created, {failed} failed.")
    return 1 if failed else 0


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run visual regression tests for lib/nodes.typ"
    )
    parser.add_argument(
        "--update",
        action="store_true",
        help="Overwrite existing reference PNGs with newly generated output",
    )
    parser.add_argument(
        "tests",
        nargs="*",
        metavar="test-name",
        help="Names of specific tests to run (omit extension). Runs all if omitted.",
    )
    args = parser.parse_args()
    sys.exit(run_tests(args.tests, args.update))


if __name__ == "__main__":
    main()
