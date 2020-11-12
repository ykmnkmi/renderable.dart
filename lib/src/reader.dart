import 'tokenizer.dart';
import 'utils.dart';

class TokenReader {
  TokenReader(Iterable<Token> tokens) : _iterator = tokens.iterator {
    _iterator.moveNext();
  }

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

  Token peek() {
    return _peek = next();
  }

  bool skip(String type, [bool all = false]) {
    if (peek()?.type == type) {
      next();

      if (all) {
        skip(type, all);
      }

      return true;
    }

    return false;
  }

  Token expect(String type) {
    if (this.current == null || this.current.type != type) {
      error('expected token $type, got ${this.current}');
    }

    final current = this.current;
    moveNext();
    return current;
  }

  Token expected(String type) {
    final token = next();

    if (token == null || token.type != type) {
      error('expected token $type, got $token');
    }

    return token;
  }
}
