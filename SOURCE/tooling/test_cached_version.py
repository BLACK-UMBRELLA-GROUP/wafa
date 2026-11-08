#!/usr/bin/env python3
"""Check the cache validator CLI with retained, synthetic SDK fixtures.

Uses only Python's standard library and an existing raw cached Dart executable.
The caller owns the new scratch directory and moves it intact after inspection.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest


VALIDATOR = Path(__file__).with_name("cached_version.dart").resolve()
REQUIRED = {
    "frameworkVersion": "3.44.2",
    "channel": "stable",
    "repositoryUrl": "https://example.invalid/flutter.git",
    "frameworkRevision": "c9a6c484230f8b5e408ec57be1ef71dee1e77020",
    "frameworkCommitDate": "2026-01-01",
    "engineRevision": "synthetic-engine-revision",
    "dartSdkVersion": "3.12.2",
    "devToolsVersion": "synthetic-devtools-version",
    "flutterVersion": "3.44.2",
}
OPTIONAL = ("engineCommitDate", "engineContentHash", "engineBuildDate")
TOOLS = ("dart-sdk/bin/dart", "flutter_tools.snapshot")


class CachedVersionTests(unittest.TestCase):
    dart = None
    scratch = None
    case_count = 0

    def fixture(self, manifest=None, *, raw=None, missing=()):
        CachedVersionTests.case_count += 1
        root = self.scratch / f"case {self.case_count:03d}"
        cache = root / "bin" / "cache"
        cache.mkdir(parents=True)
        if "flutter.version.json" not in missing:
            payload = json.dumps(REQUIRED if manifest is None else manifest)
            (cache / "flutter.version.json").write_text(
                payload if raw is None else raw, encoding="utf-8"
            )
        for name in TOOLS:
            if name not in missing:
                tool = cache / name
                tool.parent.mkdir(parents=True, exist_ok=True)
                # The validator checks existence; these files are never run.
                tool.write_text("", encoding="utf-8")
        return root

    def check_cli(self, arguments, code, diagnostic=""):
        env = dict(os.environ, DART_SUPPRESS_ANALYTICS="true",
                   FLUTTER_SUPPRESS_ANALYTICS="true")
        result = subprocess.run(
            [self.dart, str(VALIDATOR), *map(str, arguments)],
            cwd=self.scratch, env=env, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, code, result.stderr)
        self.assertEqual(result.stdout, "")
        if diagnostic:
            self.assertIn(diagnostic, result.stderr)
        else:
            self.assertEqual(result.stderr, "")

    def test_valid_required_metadata(self):
        self.check_cli([self.fixture()], 0)

    def test_optional_metadata_accepts_null_or_strings(self):
        for value in (None, "", "synthetic-value"):
            with self.subTest(value=value):
                manifest = dict(REQUIRED, **dict.fromkeys(OPTIONAL, value))
                self.check_cli([self.fixture(manifest)], 0)

    def test_argument_count(self):
        for arguments in ([], ["unused-root", "extra"]):
            with self.subTest(arguments=arguments):
                self.check_cli(arguments, 2, "Usage: cached_version.dart FLUTTER_ROOT")

    def test_malformed_or_nonobject_json(self):
        for payload in ("{", "[]", "null", '"version"'):
            with self.subTest(payload=payload):
                diagnostic = ("Unexpected" if payload == "{" else
                              "Flutter version cache must be a JSON object.")
                self.check_cli([self.fixture(raw=payload)], 1, diagnostic)

    def test_required_fields_reject_missing_empty_or_nonstring_values(self):
        for field in REQUIRED:
            for kind in ("missing", "empty", "number", "null"):
                with self.subTest(field=field, kind=kind):
                    manifest = dict(REQUIRED)
                    if kind == "missing":
                        manifest.pop(field)
                    else:
                        manifest[field] = {"empty": "", "number": 7, "null": None}[kind]
                    self.check_cli(
                        [self.fixture(manifest)], 1,
                        f"Flutter version cache has an invalid {field}.",
                    )

    def test_optional_fields_reject_nonstring_values(self):
        for field in OPTIONAL:
            with self.subTest(field=field):
                manifest = dict(REQUIRED, **{field: 7})
                self.check_cli(
                    [self.fixture(manifest)], 1,
                    f"Flutter version cache has an invalid {field}.",
                )

    def test_each_release_pin_is_enforced(self):
        for field in ("frameworkVersion", "flutterVersion", "frameworkRevision"):
            with self.subTest(field=field):
                manifest = dict(REQUIRED, **{field: "different-release"})
                self.check_cli(
                    [self.fixture(manifest)], 1,
                    "Wafa tooling is pinned to the cached Flutter 3.44.2 release.",
                )

    def test_missing_manifest_or_cached_tool_is_rejected(self):
        for name in ("flutter.version.json", *TOOLS):
            with self.subTest(name=name):
                self.check_cli(
                    [self.fixture(missing=(name,))], 1,
                    "Cached Flutter tooling unavailable:",
                )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", required=True, help="existing raw cached Dart executable")
    parser.add_argument("--scratch", required=True, type=Path,
                        help="new retained fixture directory under an existing parent")
    args = parser.parse_args()
    dart = shutil.which(args.dart)
    if dart is None:
        parser.error("the supplied Dart executable is unavailable")
    scratch = args.scratch.absolute()
    if scratch.exists() or not scratch.parent.is_dir():
        parser.error("scratch must be a new directory under an existing parent")
    scratch.mkdir()
    CachedVersionTests.dart = dart
    CachedVersionTests.scratch = scratch
    print(f"Retained fixtures: {scratch}", flush=True)
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(CachedVersionTests)
    )
    print(f"Fixture cases: {CachedVersionTests.case_count}", flush=True)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
