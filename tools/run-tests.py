#!/usr/bin/env python3
"""Build native probes; run isolated headless, interaction and optional UI tests."""
import argparse
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--graphics", action="store_true",
                        help="also render a smoke frame and every example (requires a display)")
    parser.add_argument("--no-build", action="store_true", help="use already built libraries")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build")
    parser.add_argument("--sbcl", default="sbcl")
    parser.add_argument("--quicklisp-setup", type=Path)
    parser.add_argument("--timeout", type=int, default=120, help="seconds per Lisp process")
    args = parser.parse_args()
    build = args.build_dir.resolve()
    if not args.no_build:
        subprocess.run(["cmake", "-S", str(ROOT), "-B", str(build),
                        "-DCL_RAYGUI_BUILD_TESTS=ON", "-DCMAKE_BUILD_TYPE=Release"], check=True)
        subprocess.run(["cmake", "--build", str(build), "--config", "Release"], check=True)

    def library(name):
        filenames = ([name + ".dll", "lib" + name + ".dll"] if sys.platform == "win32"
                     else ["lib" + name + (".dylib" if sys.platform == "darwin" else ".so")])
        for directory in (build, build / "Release", build / "Debug"):
            for filename in filenames:
                path = directory / filename
                if path.is_file():
                    return path
        raise FileNotFoundError(f"Missing {name} in {build}; build with CL_RAYGUI_BUILD_TESTS=ON")

    production = library("raygui")
    probe = library("raygui_abi_probe")
    interaction = library("raygui_interaction")
    env = os.environ.copy()
    env["CL_RAYGUI_REQUIRE_NATIVE_TESTS"] = "1"
    env["CL_RAYGUI_ABI_PROBE"] = str(probe)
    # Keep all compilation output in the build directory, including dependencies.
    cache = (build / "lisp-cache").as_posix() + "/"
    env["ASDF_OUTPUT_TRANSLATIONS"] = f'(:output-translations (t ("{cache}" :implementation)) :ignore-inherited-configuration)'
    if args.quicklisp_setup:
        env["CL_RAYGUI_QUICKLISP_SETUP"] = str(args.quicklisp_setup.resolve())

    def run(mode, example=None):
        child = env.copy()
        child["CL_RAYGUI_TEST_MODE"] = mode
        child["CL_RAYGUI_LIBRARY"] = str(interaction if mode == "interaction" else production)
        label = f"example {example.name}" if example else mode
        if example:
            child["CL_RAYGUI_TEST_EXAMPLE"] = str(example)
        print(f"\n=== {label} ===", flush=True)
        script = ROOT / "tests" / ("run-example.lisp" if example else "run.lisp")
        subprocess.run([args.sbcl, "--noinform", "--non-interactive", "--load", str(script)],
                       cwd=ROOT, env=child, check=True, timeout=args.timeout)

    run("headless")
    run("interaction")
    run("examples")
    if args.graphics:
        run("graphics")
        for example in sorted((ROOT / "examples").glob("*.lisp")):
            run("graphics", example)
    else:
        print("\nGraphics and rendered example checks SKIPPED; use --graphics with a working display.")
    print("\nAll requested test suites passed.")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError) as error:
        print(f"\nTest run FAILED: {error}", file=sys.stderr)
        sys.exit(1)
