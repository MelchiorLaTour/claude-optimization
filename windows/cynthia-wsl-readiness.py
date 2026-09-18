#!/usr/bin/env python3
"""Produce a content-free WSL readiness receipt for Cynthia and Data Brain."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def run(data_brain_root: Path) -> dict:
    launcher = data_brain_root / "windows" / "data-brain-wsl.sh"
    commands = {
        "data_brain": ["bash", str(launcher), "verify"],
        "cynthia": [sys.executable, "-m", "unittest", "discover", "-s", "cynthia/tests", "-p", "test_*.py"],
    }
    results = {}
    for name, command in commands.items():
        completed = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, check=False)
        results[name] = {"exit_code": completed.returncode, "status": "PASS" if completed.returncode == 0 else "FAIL"}
    return {"schema_version": 1, "operation": "cynthia_wsl_readiness", "external_requests": False, "content_returned": False, "status": "PASS" if all(item["status"] == "PASS" for item in results.values()) else "FAIL", "checks": results}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-brain-root", required=True)
    parser.add_argument("--receipt")
    args = parser.parse_args()
    report = run(Path(args.data_brain_root).expanduser().resolve())
    rendered = json.dumps(report, sort_keys=True)
    if args.receipt:
        Path(args.receipt).expanduser().write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if report["status"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
