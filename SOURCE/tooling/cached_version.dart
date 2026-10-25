import 'dart:convert';
import 'dart:io';

/// Refuse a missing or invalid cache before Flutter can fall back to Git.
/// These fields match Flutter 3.44.2's _FlutterVersionFromFile parser.
void validateCachedFlutterRoot(String flutterRoot) {
  final cache = '$flutterRoot/bin/cache';
  final manifest = jsonDecode(
    File('$cache/flutter.version.json').readAsStringSync(),
  );
  if (manifest is! Map<String, dynamic>) {
    throw const FormatException('Flutter version cache must be a JSON object.');
  }
  const requiredFields = <String>[
    'frameworkVersion',
    'channel',
    'repositoryUrl',
    'frameworkRevision',
    'frameworkCommitDate',
    'engineRevision',
    'dartSdkVersion',
    'devToolsVersion',
    'flutterVersion',
  ];
  for (final field in requiredFields) {
    if (manifest[field] is! String || (manifest[field] as String).isEmpty) {
      throw FormatException('Flutter version cache has an invalid $field.');
    }
  }
  for (final field in <String>[
    'engineCommitDate',
    'engineContentHash',
    'engineBuildDate',
  ]) {
    if (manifest[field] != null && manifest[field] is! String) {
      throw FormatException('Flutter version cache has an invalid $field.');
    }
  }
  if (manifest['frameworkVersion'] != '3.44.2' ||
      manifest['flutterVersion'] != '3.44.2' ||
      manifest['frameworkRevision'] !=
          'c9a6c484230f8b5e408ec57be1ef71dee1e77020') {
    throw const FormatException(
      'Wafa tooling is pinned to the cached Flutter 3.44.2 release. '
      'Review this project-local integration before changing SDK versions.',
    );
  }
  for (final relativePath in <String>[
    'dart-sdk/bin/dart',
    'flutter_tools.snapshot',
  ]) {
    if (!File('$cache/$relativePath').existsSync()) {
      throw FileSystemException(
        'Required cached tool is missing.',
        '$cache/$relativePath',
      );
    }
  }
}

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: cached_version.dart FLUTTER_ROOT');
    exit(2);
  }
  try {
    validateCachedFlutterRoot(arguments.single);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exit(1);
  } on FileSystemException catch (error) {
    stderr.writeln(
      'Cached Flutter tooling unavailable: ${error.message} ${error.path ?? ''}',
    );
    exit(1);
  }
}
