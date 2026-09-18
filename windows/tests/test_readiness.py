import importlib.util
from pathlib import Path
from unittest.mock import patch
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "cynthia-wsl-readiness.py"
SPEC = importlib.util.spec_from_file_location("cynthia_wsl_readiness", MODULE_PATH)
READINESS = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(READINESS)


class Completed:
    def __init__(self, returncode: int):
        self.returncode = returncode


class ReadinessTests(unittest.TestCase):
    def test_receipt_contains_only_status_fields(self):
        with patch.object(READINESS.subprocess, "run", return_value=Completed(0)):
            report = READINESS.run(Path("/tmp/data-brain"))
        self.assertEqual(report["status"], "PASS")
        self.assertFalse(report["external_requests"])
        self.assertFalse(report["content_returned"])
        self.assertEqual(set(report["checks"]["data_brain"]), {"exit_code", "status"})

    def test_failure_is_reported_without_command_output(self):
        with patch.object(READINESS.subprocess, "run", side_effect=[Completed(1), Completed(0)]):
            report = READINESS.run(Path("/tmp/data-brain"))
        self.assertEqual(report["status"], "FAIL")
        self.assertEqual(report["checks"]["data_brain"]["status"], "FAIL")
        self.assertNotIn("stdout", str(report))
        self.assertNotIn("stderr", str(report))


if __name__ == "__main__":
    unittest.main()
