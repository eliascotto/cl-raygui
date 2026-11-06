#!/usr/bin/env python3
"""Provision pinned raylib in CI and run the test runner with Roswell's SBCL."""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def main():
    build = ROOT / "build"
    source = build / "raylib-source"
    native_build = build / "raylib-build"
    prefix = build / "raylib-prefix"
    env = os.environ.copy()

    def run(*command):
        subprocess.run(list(command), cwd=ROOT, env=env, check=True)

    run("git", "clone", "--depth", "1", "--branch", "6.0",
        "https://github.com/raysan5/raylib.git", str(source))
    configure = ["cmake", "-S", str(source), "-B", str(native_build),
                 "-DBUILD_SHARED_LIBS=ON", "-DBUILD_EXAMPLES=OFF",
                 "-DCMAKE_BUILD_TYPE=Release", f"-DCMAKE_INSTALL_PREFIX={prefix}"]
    if sys.platform == "win32":
        configure += ["-G", "Ninja"]
        env["CMAKE_GENERATOR"] = "Ninja"
    if sys.platform.startswith("linux"):
        configure.append("-DGLFW_BUILD_WAYLAND=OFF")
    run(*configure)
    run("cmake", "--build", str(native_build), "--config", "Release", "--parallel", "2")
    run("cmake", "--install", str(native_build), "--config", "Release")

    env["CMAKE_PREFIX_PATH"] = str(prefix)
    env["PATH"] = str(prefix / "bin") + os.pathsep + env["PATH"]
    library_path = "DYLD_LIBRARY_PATH" if sys.platform == "darwin" else "LD_LIBRARY_PATH"
    env[library_path] = str(prefix / "lib") + os.pathsep + env.get(library_path, "")
    executable = "sbcl.exe" if sys.platform == "win32" else "sbcl"
    implementations = Path.home() / ".roswell" / "impls"
    candidates = sorted(implementations.rglob(executable))
    if not candidates:
        raise FileNotFoundError(f"No {executable} installed under {implementations}")
    sbcl = candidates[-1]
    # Roswell normally supplies this environment variable when launching SBCL.
    cores = list(sbcl.parent.parent.rglob("sbcl.core"))
    if cores:
        env["SBCL_HOME"] = str(cores[0].parent)
    command = [sys.executable, str(ROOT / "tools/run-tests.py"), "--sbcl", str(sbcl),
               "--quicklisp-setup", str(ROOT / ".qlot/setup.lisp"), "--timeout", "180"]
    if sys.platform.startswith("linux"):
        # Software OpenGL on a virtual display, no physical desktop required.
        env["LIBGL_ALWAYS_SOFTWARE"] = "1"
        command += ["--graphics"]
        command = ["xvfb-run", "-a"] + command
    run(*command)


if __name__ == "__main__":
    main()
