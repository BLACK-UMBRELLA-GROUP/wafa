#!/usr/bin/env python3
"""Check cached-wrapper command refusals without an SDK or disk fixtures."""

import os
from pathlib import Path
import shutil
import subprocess
import unittest


WRAPPER = Path(__file__).resolve().with_name("flutter_cached.sh")
BASH = shutil.which("bash")


class CachedCommandScopeTests(unittest.TestCase):
    def assert_refused(self, arguments, message):
        self.assertIsNotNone(BASH, "Bash is required to check the wrapper")
        environment = os.environ.copy()
        # /dev/null cannot contain an SDK. A refusal must happen before the
        # environment helper tries to find Dart, even on an unprepared checkout.
        environment["WAFA_FLUTTER_ROOT"] = os.devnull
        environment.pop("BASH_ENV", None)
        result = subprocess.run(
            [BASH, str(WRAPPER), *arguments],
            env=environment,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertIn(message, result.stderr)
        self.assertNotIn("cached Dart executable is unavailable", result.stderr)

    def test_missing_command_shows_usage(self):
        self.assert_refused([], "Usage: tooling/flutter_cached.sh")

    def test_commands_outside_preview_scope_are_refused(self):
        for command in ("upgrade", "channel", "doctor", "--version"):
            with self.subTest(command=command):
                self.assert_refused([command], "Command outside the Wafa preview scope")

    def test_other_pub_operations_are_refused(self):
        for arguments in (["pub"], ["pub", "upgrade"], ["pub", "cache", "repair"]):
            with self.subTest(arguments=arguments):
                self.assert_refused(arguments, "Only pub get is supported")

    def test_other_build_targets_and_signed_builds_are_refused(self):
        for arguments, message in (
            (["build"], "Only build ios is supported"),
            (["build", "apk", "--no-codesign"], "Only build ios is supported"),
            (["build", "ios"], "Use --config-only or --no-codesign"),
        ):
            with self.subTest(arguments=arguments):
                self.assert_refused(arguments, message)

    def test_version_checks_are_refused_for_permitted_commands(self):
        for arguments in (
            ["analyze", "--version-check"],
            ["test", "--version-check=true"],
            ["pub", "get", "--version-check"],
            ["assemble", "--version-check=false"],
            ["build", "ios", "--config-only", "--version-check"],
        ):
            with self.subTest(arguments=arguments):
                self.assert_refused(arguments, "Version checking is disabled")

    def test_signing_and_configuration_overrides_are_refused(self):
        for option in ("--codesign", "--codesign=true", "--no-config-only"):
            with self.subTest(option=option):
                self.assert_refused(
                    ["build", "ios", "--no-codesign", option],
                    "Signing and configuration overrides are outside",
                )


if __name__ == "__main__":
    unittest.main()
