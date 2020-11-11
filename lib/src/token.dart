part of 'tokenizer.dart';

abstract class TokenType {
  static const String add = 'add';
  static const String assign = 'assign';
  static const String colon = 'colon';
  static const String comma = 'comma';
  static const String comment = 'comment';
  static const String commentEnd = 'commentend';
  static const String commentBegin = 'commentbegin';
  static const String div = 'div';
  static const String dot = 'dot';
  static const String eq = 'eq';
  static const String error = 'error';
  static const String variableEnd = 'variableend';
  static const String variableBegin = 'variablebegin';
  static const String float = 'float';
  static const String floorDiv = 'floordiv';
  static const String gt = 'gt';
  static const String gteq = 'gteq';
  static const String integer = 'integer';
  static const String lBrace = 'lbrace';
  static const String lBracket = 'lbracket';
  static const String lParen = 'lparen';
  static const String lt = 'lt';
  static const String lteq = 'lteq';
  static const String mod = 'mod';
  static const String mul = 'mul';
  static const String name = 'name';
  static const String ne = 'ne';
  static const String operator = 'operator';
  static const String pipe = 'pipe';
  static const String pow = 'pow';
  static const String rBrace = 'rbrace';
  static const String rBracket = 'rbracket';
  static const String rParen = 'rparen';
  static const String semicolon = 'semicolon';
  static const String blockEnd = 'blockend';
  static const String blockBegin = 'blockbegin';
  static const String string = 'string';
  static const String sub = 'sub';
  static const String text = 'text';
  static const String tilde = 'tilde';
  static const String whiteSpace = 'whitespace';
}

abstract class Token {
  static final Map<String, String> lexemes = <String, String>{
    TokenType.add: '+',
    TokenType.assign: '=',
    TokenType.colon: ':',
    TokenType.comma: ',',
    TokenType.div: '/',
    TokenType.dot: '.',
    TokenType.eq: '==',
    TokenType.floorDiv: '//',
    TokenType.gt: '>',
    TokenType.gteq: '>=',
    TokenType.lBrace: '{',
    TokenType.lBracket: '[',
    TokenType.lParen: '(',
    TokenType.lt: '<',
    TokenType.lteq: '<=',
    TokenType.mod: '%',
    TokenType.mul: '*',
    TokenType.ne: '!=',
    TokenType.pipe: '|',
    TokenType.pow: '**',
    TokenType.rBrace: '}',
    TokenType.rBracket: ']',
    TokenType.rParen: ')',
    TokenType.semicolon: ';',
    TokenType.sub: '-',
    TokenType.tilde: '~',
    TokenType.whiteSpace: ' ',
  };

  const factory Token(int start, String type, String lexeme) = LexemeToken;

  const factory Token.simple(int start, String type) = SimpleToken;

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
    if (identical(this, other)) return true;
    return other is Token && type == other.type && start == other.start && value == other.value;
  }

  bool test(String expression);

  @override
  String toString() {
    return '#$type:$start $value';
  }
}

@immutable
abstract class BaseToken implements Token {
  const BaseToken();

  @override
  int get end {
    return start + length;
  }

  @override
  int get length {
    return value.length;
  }

  @override
  bool test(String expression) {
    if (type == expression) {
      return true;
    } else if (expression.contains(':')) {
      final parts = expression.split(':').take(2);
      return type == parts.first && value == parts.last;
    }

    return false;
  }

  @override
  String toString() {
    return '#$type:$start:$length $value';
  }
}

class LexemeToken extends BaseToken {
  const LexemeToken(this.start, this.type, this.value);

  @override
  final int start;

  @override
  final String type;

  @override
  final String value;
}

class SimpleToken extends BaseToken {
  const SimpleToken(this.start, this.type);

  @override
  final int start;

  @override
  final String type;

  @override
  String get value {
    return Token.lexemes[type];
  }
}
