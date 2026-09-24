"""Exercise build helpers through bash, as the flake app wrapper does."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DarwinBuildScriptsTest(unittest.TestCase):
    def run_helper(self, script, failed_command=""):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            log = work / "calls.jsonl"
            stub = work / "stub"
            stub.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "command = Path(sys.argv[0]).name\n"
                "with open(os.environ['CALL_LOG'], 'a') as log:\n"
                "    log.write(json.dumps([command, *sys.argv[1:]]) + '\\n')\n"
                "sys.exit(42 if command == os.environ['FAIL_COMMAND'] else 0)\n"
            )
            stub.chmod(0o755)
            for command in ("git", "nix", "sudo", "unlink"):
                (work / command).symlink_to(stub)
            result = subprocess.run(
                ["bash", str(ROOT / "apps/aarch64-darwin" / script),
                 "--option", "test-option", "value with spaces"],
                cwd=work,
                env={**os.environ, "PATH": f"{work}:{os.environ['PATH']}",
                     "CALL_LOG": str(log), "FAIL_COMMAND": failed_command},
                capture_output=True, text=True,
            )
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            return result, calls

    def test_failures_stop_before_later_steps(self):
        for script, commands in (
            ("build-switch", ["git", "nix", "sudo", "unlink"]),
            ("build", ["nix", "unlink"]),
        ):
            for index, command in enumerate(commands):
                with self.subTest(script=script, failure=command):
                    result, calls = self.run_helper(script, command)
                    self.assertEqual(result.returncode, 42)
                    self.assertEqual([call[0] for call in calls], commands[:index + 1])
                    self.assertNotIn("complete!", result.stdout)

    def test_success_and_argument_boundaries(self):
        for script, commands in (
            ("build-switch", ["git", "nix", "sudo", "unlink"]),
            ("build", ["nix", "unlink"]),
        ):
            with self.subTest(script=script):
                result, calls = self.run_helper(script)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual([call[0] for call in calls], commands)
                self.assertIn("complete!", result.stdout)
                self.assertNotIn(r"\033", result.stdout)
                for call in calls:
                    if call[0] in ("nix", "sudo"):
                        self.assertEqual(call[-3:], ["--option", "test-option", "value with spaces"])


if __name__ == "__main__":
    unittest.main()
