import 'tokenizer.dart';

class TokenReader {
  TokenReader(Iterable<Token> tokens) : _iterator = tokens.iterator;

  final Iterator<Token> _iterator;

  Token _peek;

  Token get current {
    return _iterator.current;
  }

  bool moveNext() {
    if (_peek != null) {
      _peek = null;
      return true;
    }

    return _iterator.moveNext();
  }

  Token next() {
    if (_peek != null) {
      final token = _peek;
      _peek = null;
      return token;
    }

    return _iterator.moveNext() ? _iterator.current : null;
  }

  bool nextIf(String expression) {
    if (current.test(expression)) {
      next();
      return true;
    }

    return false;
  }

  Token peek() {
    return _peek = next();
  }

  bool skipIf(String expression, [bool all = false]) {
    if (peek().test(expression)) {
      next();

      if (all) {
        skipIf(expression, all);
      }

      return true;
    }

    return false;
  }

  Token expect(String expression) {
    if (this.current == null || !this.current.test(expression)) {
      throw 'expected token $expression, got ${this.current}';
    }

    final current = this.current;
    moveNext();
    return current;
  }

  Token expected(String type) {
    final token = next();

    if (token == null || token.type != type) {
      throw 'expected token $type, got $token';
    }

    return token;
  }
}
