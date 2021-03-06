// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_cli.directory_package_reporter;

import 'dart:io';

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:path/path.dart' as path;

import '../../shapeshift_common.dart';

/// A [PackageReporter] that calculates the diff between APIs found in two
/// directories.
///
/// The constructor takes the paths of the two directories, and a [WriterProvider].
/// After it has been constructed, a [DirectoryPackageReporter] can calculate
/// the diffs of all the files in the two directories, recursively, with
/// [calculateAllDiffs], and can report the diffs into the [WriterProvider] with
/// [report].
class DirectoryPackageReporter extends PackageReporter {
  final String leftPath, rightPath;

  DirectoryPackageReporter(this.leftPath, this.rightPath);

  void _calculateDiff(PackageReport report, String fileName) {
    File left = new File(path.join(leftPath, fileName));
    File right = new File(path.join(rightPath, fileName));
    if (!left.existsSync()) {
      String associatedLibrary = associatedLibraryJsonPath(left.path);
      if (associatedLibrary != null) {
        // fileName not found in the left path, which will be noted in the
        // library JSON file. Don't worry about it.
      } else {
        print('Hmm... "${left.path} doesn\'t exist, which is weird.');
      }
      return;
    }
    report.add(
        fileName, diffApis(left.readAsStringSync(), right.readAsStringSync()));
  }

  PackageReport calculateAllDiffs() {
    List rightRawLs = new Directory(rightPath).listSync(recursive: true);
    List rightLs = rightRawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    var report = new PackageReport();

    rightLs.forEach((String file) {
      file = path.relative(file, from: rightPath);
      if (path.basename(file) == 'index.json' ||
          path.basename(file) == 'library_list.json' ||
          path.extension(file) != '.json') {
        print('Skipping $file');
        return;
      }
      _calculateDiff(report, file);
    });

    return report;
  }
}
