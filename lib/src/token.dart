part of 'lexer.dart';

abstract class Token {
  static const Map<String, String> common = <String, String>{
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
  };

  const factory Token(int line, String type, String value) = _ValueToken;

  const factory Token.simple(int line, String type) = _SimpleToken;

  @override
  int get hashCode {
    return type.hashCode & line & value.hashCode;
  }

  int get line;

  int get length;

  String get type;

  String get value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Token && type == other.type && line == other.line && value == other.value;
  }

  Token change({int line, String type, String value});

  bool test(String expressionOrType, [String? value]);

  bool testAny(Iterable<String> expressions);

  @override
  String toString() {
    if (value.isEmpty) {
      return '#$type:$line';
    }

    return '#$type:$line $value';
  }
}

@immutable
abstract class _BaseToken implements Token {
  const _BaseToken();

  @override
  int get length {
    return value.length;
  }

  @override
  Token change({int? line, String? type, String? value}) {
    line ??= this.line;
    value ??= this.value;

    if (type != null && Token.common.containsKey(type)) {
      if (Token.common[type] != value) {
        throw this;
      }

      value = null;
    } else {
      type = this.type;
    }

    return value == null ? Token.simple(line, type) : Token(line, type, value);
  }

  @override
  bool test(String expressionOrType, [String? value]) {
    if (value == null) {
      if (expressionOrType == type) {
        return true;
      }

      if (expressionOrType.contains(':')) {
        var parts = expressionOrType.split(':');
        return type == parts.first && this.value == parts.last;
      }

      return false;
    }

    return expressionOrType == type && value == this.value;
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
    if (value.isEmpty) {
      return '$type:$line';
    }

    return '$type:$line:$length \'${value.replaceAll('\'', '\\\'').replaceAll('\n', r'\n')}\'';
  }
}

class _SimpleToken extends _BaseToken {
  const _SimpleToken(this.line, this.type);

  @override
  final int line;

  @override
  final String type;

  @override
  String get value {
    return Token.common[type] ?? '';
  }
}

class _ValueToken extends _BaseToken {
  const _ValueToken(this.line, this.type, this.value);

  @override
  final int line;

  @override
  final String type;

  @override
  final String value;
}
