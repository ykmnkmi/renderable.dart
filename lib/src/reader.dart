import 'exceptions.dart';
import 'lexer.dart';

class TokenReader {
  TokenReader(Iterable<Token> tokens)
      : _iterator = tokens.iterator,
        _pushed = <Token>[] {
    _current = Token.simple(0, 'initial');
    next();
  }

  final Iterator<Token> _iterator;

  final List<Token> _pushed;

  late Token _current;

  Token get current {
    return _current;
  }

  Iterable<Token> get values {
    return TokenIterable(this);
  }

  void push(Token token) {
    _pushed.add(token);
  }

  Token look() {
    var old = next();
    var result = current;
    push(result);
    _current = old;
    return result;
  }

  void skip([int n = 1]) {
    for (var i = 0; i < n; i += 1) {
      next();
    }
  }

  Token? nextIf(String type, [String? value]) {
    if (_current.test(type, value)) {
      return next();
    }

    return null;
  }

  bool skipIf(String type, [String? value]) {
    return nextIf(type, value) != null;
  }

  Token next() {
    final result = _current;

    if (_pushed.isNotEmpty) {
      _current = _pushed.removeAt(0);
    } else if (_current.type != 'eof') {
      if (_iterator.moveNext()) {
        _current = _iterator.current;
      } else {
        eof();
      }
    }

    return result;
  }

  void eof() {
    _current = Token.simple(current.line + current.length, 'eof');
  }

  Token expect(String type, [String? value]) {
    if (!_current.test(type, value)) {
      if (_current.type == 'eof') {
        throw TemplateSyntaxError('unexpected end of template, expected $type');
      }

      throw TemplateSyntaxError('expected token $type, got $_current');
    }

    return next();
  }
}

class TokenIterable extends Iterable<Token> {
  TokenIterable(this.reader);

  final TokenReader reader;

  @override
  Iterator<Token> get iterator {
    return _TokenIterator(reader);
  }
}

class _TokenIterator extends Iterator<Token> {
  _TokenIterator(this.reader);

  final TokenReader reader;

  @override
  Token get current {
    return reader.next();
  }

  @override
  bool moveNext() {
    if (reader.current.test('eof')) {
      reader.eof();
      return false;
    }

    return true;
  }
}
