"""Check preview command validation without preparing dependencies or building."""

import os
from pathlib import Path
import shutil
import subprocess
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "run.sh"
BASH = shutil.which("bash")


class RunCliTests(unittest.TestCase):
    def run_cli(self, *arguments):
        self.assertIsNotNone(BASH, "Bash is required to check run.sh")
        # A file cannot contain an SDK. If validation regresses, the wrapper
        # must stop before any build even on a checkout with prepared packages.
        environment = dict(os.environ)
        environment["WAFA_FLUTTER_ROOT"] = os.path.join(
            os.devnull, "wafa-run-cli-test-sdk"
        )
        return subprocess.run(
            [BASH, str(RUNNER), *arguments],
            cwd="/",
            env=environment,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def assert_rejected(self, arguments, message):
        result = self.run_cli(*arguments)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertIn(message, result.stderr)
        self.assertNotIn("Dependencies are not prepared", result.stderr)
        self.assertNotIn("cached Dart executable is unavailable", result.stderr)

    def test_help_exits_successfully_without_setup(self):
        for option in ("--help", "-h"):
            with self.subTest(option=option):
                result = self.run_cli(option)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Usage: ./run.sh --device DEVICE_ID", result.stdout)
                self.assertIn("./run.sh --build-only [--unsigned]", result.stdout)
                self.assertEqual(result.stderr, "")

    def test_no_arguments_requires_a_delivery_target(self):
        self.assert_rejected((), "Usage: ./run.sh --device DEVICE_ID")

    def test_unknown_options_are_rejected_even_with_a_device(self):
        for arguments in (("--unknown",), ("--device", "demo", "--unknown")):
            with self.subTest(arguments=arguments):
                self.assert_rejected(arguments, "Unknown argument: --unknown")

    def test_device_requires_a_nonempty_value_before_another_option(self):
        for arguments in (("--device",), ("--device", ""), ("--device", "--build-only")):
            with self.subTest(arguments=arguments):
                self.assert_rejected(
                    arguments, "--device requires the paired device ID or name."
                )

    def test_unsigned_device_delivery_is_rejected_in_either_option_order(self):
        for arguments in (
            ("--device", "demo", "--unsigned"),
            ("--unsigned", "--device", "demo"),
        ):
            with self.subTest(arguments=arguments):
                self.assert_rejected(arguments, "--unsigned requires --build-only")


if __name__ == "__main__":
    unittest.main()
