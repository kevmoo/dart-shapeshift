Shapeshift
==========

Understand how the shape of your Dart package is shifting.

Execute shapeshift against two versions of your Dart docgen-generated API to
expose how your API has changed. Shapeshift generates a set of markdown files
that list API differences in your Dart package.

(The Shapeshift repository also contains the Dart doc coverage tool, documented
in [it's own README](COVERAGE_README.md).)

Shapeshift can be used as a command-line script, or as Dart library.

The shapeshift.dart script
==========================

The shapeshift package comes with a command-line tool, `bin/shapeshift.dart`.
This tool can read JSON-formatted API files (generated by dartdoc), and output,
in Markdown format, a list of differences.

Basic example
-------------

Assuming you have two versions of your docgen-generated docs at:

```bash
/Code/my_package/docs/docs-v1.6.0/
/Code/my_package/docs/docs-v1.7.0/
```

Then you can run the following command to generate reports of the API
differences.

```bash
dart bin/shapeshift.dart \
    --base=/Code/my_package/docs \
    --out=./diff-1.6.0_1.7.0 \
    docs-v1.6.0 \
    docs-v1.7.0
```

In this command, `--base` specifies the directory where your two documentation
directories live. `--out` specifies a new or existing directory where you want
the output markdown files to be written. The final two arguments are the
directory with the _old_ and the directory with the _new_ documentation.

This command will create the output directory, if it wasn't there, and write a
markdown file for each library that was examined. For example, if a
`dart-async.json` file was found, documenting the `dart:async` library, then
the output will include a `dart:async.markdown` file.

Each library's markdown file will then include all of the changes found for the
library itself, and for every class within the library.

The directory of markdown files works surprisingly well with
[Jekyll](http://jekyllrb.com/) and Jekyll's basic template, but we're working
on more streamlined output options.

Options
-------

The shapeshift Dart script accepts the following options:

* `--base` is the file path that the two directories (old and new) have in
  common.
* `--out` is an optional directory where the API changes can be written to.
  Shapeshift will write a separate Markdown file for each library it finds.
  Each Markdown file will include changes for all member classes of a library.
  If `--out` is not used, the differences, still in Markdown format, will be
  printed to stdout.

Using the Dart library
======================

Shapeshift can also be used with other Dart code as a library. I would
recommend importing `'package:shapeshift/shapeshift_common.dart'`. The
[tests](test/shapeshift/) can be used as examples.

`shapeshift_common` library example
---------------------------------------------------

Assuming you have two versions of a class's API sitting on disk, say at
`v1/foo.Foo.json`, and `v2/foo.Foo.json`, you may diff them as follows:

```dart
import 'package:shapeshift/shapeshift_common.dart';

void main() {
  String v1 = new File('v1/foo.Foo.json')..readAsStringSync();
  String v2 = new File('v2/foo.Foo.json')..readAsStringSync();

  // Calculate the diff between the two APIs.
  DiffNode diff = diffApis(v1, v2);

  // ReadableStringSink is just a class that acts like a StringSink, but can be
  // read at any point. You can also use a File handle.
  ReadableStringSink io = new ReadableStringSink();

  // The MarkdownWriter takes a callback that will instantiate the write
  // target, if it needs to be written to.
  MarkdownWriter writer = new MarkdownWriter(() => io, false);

  // Create a new ClassReporter for the diff, which can report to the writer.
  // And write!
  new ClassReporter(diff, writer).report();

  // Now io contains the report, in Markdown format.
  print(io.read());
}
```

`shapeshift_common` API
-----------------------

TODO: Publish shapeshift as a package, so that it's API is online.

For now, the [tests](test/shapeshift/) serve as good examples of how to use the
API.

License
=======

[Apache v2](LICENSE)

Contributing
============

Contributions welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

Disclaimer
==========

This is not an official Google product.
