part of 'lexer.dart';

abstract class Token {
  static final Map<String, String> common = <String, String>{
    'add': '+',
    'assign': '=',
    'colon': ':',
    'comma': ',',
    'div': '/',
    'dot': '.',
    'eq': '==',
    'eof': '',
    'floordiv': '//',
    'gt': '>',
    'gteq': '>=',
    'initial': '',
    'lbrace': '{',
    'lbracket': '[',
    'lparen': '(',
    'lt': '<',
    'lteq': '<=',
    'mod': '%',
    'mul': '*',
    'ne': '!=',
    'pipe': '|',
    'pow': '**',
    'rbrace': '}',
    'rbracket': ']',
    'rparen': ')',
    'semicolon': ';',
    'sub': '-',
    'tilde': '~',
    'whitespace': ' ',
  };

  const factory Token(int start, String type, String value) = _ValueToken;

  const factory Token.simple(int start, String type) = _SimpleToken;

  @override
  int get hashCode {
    return type.hashCode & start & value.hashCode;
  }

  int get start;

  int get end;

  int get length;

  String get type;

  String get value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Token && type == other.type && start == other.start && value == other.value;
  }

  Token change({int start, String type, String value});

  bool test(String type, [String? value]);

  bool testAny(Iterable<String> expressions);

  @override
  String toString() {
    return '#$type:$start $value';
  }
}

@immutable
abstract class _BaseToken implements Token {
  const _BaseToken();

  @override
  int get end {
    return start + length;
  }

  @override
  int get length {
    return value.length;
  }

  @override
  Token change({int? start, String? type, String? value}) {
    start ??= this.start;
    value ??= this.value;

    if (type != null && Token.common.containsKey(type)) {
      if (Token.common[type] != value) {
        throw this;
      }

      value = null;
    } else {
      type = this.type;
    }

    return value == null ? Token.simple(start, type) : Token(start, type, value);
  }

  @override
  bool test(String type, [String? value]) {
    if (value == null) {
      if (type == this.type) {
        return true;
      }

      if (type.contains(':')) {
        var parts = type.split(':');
        return this.type == parts.first && this.value == parts.last;
      }

      return false;
    }

    return type == this.type && value == this.value;
  }

  @override
  bool testAny(Iterable<String> expressions) {
    for (var expression in expressions) {
      if (test(expression)) {
        return true;
      }
    }

    return false;
  }

  @override
  String toString() {
    return '$type:$start:$length $value';
  }
}

class _SimpleToken extends _BaseToken {
  const _SimpleToken(this.start, this.type);

  @override
  final int start;

  @override
  final String type;

  @override
  String get value {
    return Token.common[type]!;
  }
}

class _ValueToken extends _BaseToken {
  const _ValueToken(this.start, this.type, this.value);

  @override
  final int start;

  @override
  final String type;

  @override
  final String value;
}
