// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:shapeshift/shapeshift_cli.dart';
import 'package:shapeshift/shapeshift_common.dart';

class Shapeshift {
  ArgResults args;

  void go(List<String> arguments) {
    parseArgs(arguments);
    if (args.rest.isEmpty) {
      print('Usage: shapeshift.dart [options] <leftDir> <rightDir>');
      exit(0);
    }
    String left = args.rest[0];
    String right = args.rest[1];
    String leftPath = path.join(args['base'], left);
    String rightPath = path.join(args['base'], right);
    if (args['subset'].isNotEmpty) {
      leftPath = path.join(leftPath, args['subset']);
      rightPath = path.join(rightPath, args['subset']);
    }

    WriterProvider writer = (args['out'] == null)
        ? new SingleSinkWriterProvider(stdout)
        : new DirectoryDiffWriterProvider(args['out']);

    var report =
        new DirectoryPackageReporter(leftPath, rightPath).calculateAllDiffs();

    report.write(writer);
  }

  void parseArgs(List<String> arguments) {
    var parser = new ArgParser();
    parser.addOption('base',
        defaultsTo: '/Users/srawlins/code/dartlang.org/api-docs');
    parser.addOption('subset', defaultsTo: '');
    parser.addOption('out');
    args = parser.parse(arguments);
  }
}

void main(List<String> arguments) => new Shapeshift().go(arguments);
