// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

class HtmlWriterProvider extends WriterProvider {
  HtmlWriter sink;
  HtmlWriterProvider(this.sink);

  MarkdownWriter writerFor(String _) =>
      new MarkdownDiffWriter(
          () => sink, shouldClose: false, shouldWriteMetadata: false);
}