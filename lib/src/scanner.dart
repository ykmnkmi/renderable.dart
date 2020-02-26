import 'package:petitparser/petitparser.dart';

// import 'token.dart';

enum TokenType {
  text,
  unexpected,
  eof,
}

class Tokenizer {
  static final Parser<String> exprBegin = string('{{').seq(whitespace().star()).pick<String>(0);
  static final Parser<String> exprEnd = whitespace().star().seq(string('}}')).pick<String>(1);
  static final Parser<String> name = letter().plus().flatten();
  static final Parser<String> expr = exprBegin.seq(name).seq(exprEnd).pick<String>(1);
  static final Parser<String> text = any().plusLazy(exprBegin).or(any().plus()).flatten();
  static final Parser<List<String>> interpolation = (expr | text).star().castList<String>();

  const Tokenizer();

  Iterable<Token<String>> tokenize(String template) sync* {
    Result<Token<String>> result = textParser.parse(template);

    if (result.isSuccess) {
      yield result.value;
    }
  }
}
