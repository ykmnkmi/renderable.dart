library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

part 'token.dart';

class Tokenizer {
  @literal
  const Tokenizer();

  Iterable<Token> tokenize(String template, {String path}) sync* {
    final SpanScanner scanner = SpanScanner(template, sourceUrl: path);

    while (!scanner.isDone) {
      LineScannerState start = scanner.state;
      LineScannerState end = start;

      while (!scanner.isDone) {
    }
  }
}
