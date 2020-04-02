library tokenizer;

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

part 'token.dart';

const Pattern commentStart = '{#';
const Pattern commentEnd = '#}';
const Pattern expressionStart = '{{';
const Pattern expressionEnd = '}}';
const Pattern statementStart = '{%';
const Pattern statementEnd = '%}';

class Tokenizer {
  @literal
  const Tokenizer();

  Iterable<Token> tokenize(String template, {String path}) sync* {
    final SpanScanner scanner = SpanScanner(template, sourceUrl: path);

    while (!scanner.isDone) {
      int start = scanner.position;
      int end = start;

      String text;

      while (!scanner.isDone) {
        if (scanner.scan(commentStart)) {
          // comment start

          text = scanner.substring(start, end);

          if (text.isNotEmpty) {
            yield Token.text(start, text);
          }

          yield Token.commentStart(end);

          end = scanner.position;
          start = end;

          while (!scanner.matches(commentEnd)) {
            scanner.readChar();
          }

          end = scanner.position;
          text = scanner.substring(start, end).trim();

          if (text.isEmpty) {
            yield Token.error(end, 'expected comment body.');
          }

          if (!scanner.scan(commentEnd)) {
            yield Token.error(end, 'expected comment body.');
          }

          yield Token.comment(start, text);
          yield Token.commentEnd(end);
          end = scanner.position;
          start = end;

          // comment end
        }

        if (scanner.scan(expressionStart)) {
          break;
        }

        int char = scanner.readChar();
        end = scanner.position;
      }

      text = scanner.substring(start, end);

      if (text.isNotEmpty) {
        yield Token.text(start, text);
      }
    }
  }
}
