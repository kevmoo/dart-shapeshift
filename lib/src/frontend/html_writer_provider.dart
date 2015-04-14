// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

class HtmlWriterProvider extends Writer {
  HtmlWriter sink;
  HtmlWriterProvider(this.sink);

  /// In the SingleSinkWriter, the writer is simple the original sink.
  MarkdownWriter writerFor(String _) => new MarkdownDiffWriter(() => sink, false);
}
