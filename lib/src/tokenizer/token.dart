part of '../tokenizer.dart';

enum TokenType {
  whitespace,
  identifier,
  expression,
  expressionEnd,
  expressionStart,
  comment,
  commentEnd,
  commentStart,
  text,
  unexpected,
  eof,
}

abstract class Token {
  factory Token.whitespace(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.whitespace);
  }

  factory Token.identifier(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.identifier);
  }

  factory Token.expression(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.expression);
  }

  factory Token.expressionEnd(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.expressionEnd);
  }

  factory Token.expressionStart(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.expressionStart);
  }

  factory Token.comment(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.comment);
  }

  factory Token.commentEnd(int start) {
    return SimpleToken(start, TokenType.commentEnd);
  }

  factory Token.commentStart(int start) {
    return SimpleToken(start, TokenType.commentStart);
  }

  factory Token.text(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.text);
  }

  factory Token.unexpected(int start, String lexeme) {
    return LexemeToken(start, lexeme, TokenType.unexpected);
  }

  factory Token.eof(int start) {
    return SimpleToken(start, TokenType.eof);
  }

  int get start;

  int get end;

  int get length;

  String get lexeme;

  TokenType get type;

  @override
  int get hashCode {
    return type.hashCode & start & lexeme.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is Token &&
        type == other.type &&
        start == other.start &&
        lexeme == other.lexeme;
  }

  @override
  String toString() {
    return '#$type:$start {$lexeme}';
  }
}

abstract class BaseToken implements Token {
  @override
  int get end {
    return start + length;
  }

  @override
  int get length {
    return lexeme.length;
  }

  @override
  String toString() {
    return '#$type:$start:$length {$lexeme}';
  }
}

class SimpleToken extends BaseToken {
  static final Map<TokenType, String> lexemes = <TokenType, String>{
    TokenType.expressionEnd: '}}',
    TokenType.expressionStart: '{{',
    TokenType.commentEnd: '#}',
    TokenType.commentStart: '{#',
    TokenType.eof: '',
  };

  SimpleToken(this.start, this.type);

  @override
  final int start;

  @override
  final TokenType type;

  @override
  String get lexeme {
    return lexemes[type];
  }
}

class LexemeToken extends BaseToken {
  LexemeToken(this.start, this.lexeme, this.type);

  @override
  final int start;

  @override
  final String lexeme;

  @override
  final TokenType type;
}
