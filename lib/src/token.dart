part of 'tokenizer.dart';

abstract class Token {
  static final Map<TokenType, String> lexemes = <TokenType, String>{
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
    TokenType.whitespace: ' ',
  };

  const factory Token(int start, TokenType type, String lexeme) = LexemeToken;

  const factory Token.simple(int start, TokenType type) = SimpleToken;

  @override
  int get hashCode {
    return type.hashCode & start & value.hashCode;
  }

  int get start;

  int get end;

  int get length;

  TokenType get type;

  String get value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Token && type == other.type && start == other.start && value == other.value;
  }

  bool same(Token other);

  @override
  String toString() {
    return '#$type:$start $value';
  }
}

enum TokenType {
  add,
  assign,
  colon,
  comma,
  comment,
  commentEnd,
  commentStart,
  div,
  dot,
  eq,
  error,
  expressionEnd,
  expressionStart,
  float,
  floorDiv,
  gt,
  gteq,
  integer,
  lBrace,
  lBracket,
  lParen,
  lt,
  lteq,
  mod,
  mul,
  name,
  ne,
  operator,
  pipe,
  pow,
  rBrace,
  rBracket,
  rParen,
  semicolon,
  statementEnd,
  statementStart,
  string,
  sub,
  text,
  tilde,
  whitespace,
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
  bool same(Token other) {
    return type == other.type && value == other.value;
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
  final TokenType type;

  @override
  final String value;
}

class SimpleToken extends BaseToken {
  const SimpleToken(this.start, this.type);

  @override
  final int start;

  @override
  final TokenType type;

  @override
  String get value {
    return Token.lexemes[type];
  }
}
