part of '../tokenizer.dart';

enum TokenType {
  whitespace,
  identifier,
  interpolationEnd,
  interpolationStart,
  comment,
  commentEnd,
  commentStart,
  text,
  unexpected,
  eof,
}

abstract class Token {
  factory Token.whitespace(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.whitespace);

  factory Token.identifier(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.identifier);

  factory Token.interpolationEnd(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.interpolationEnd);

  factory Token.interpolationStart(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.interpolationStart);

  factory Token.comment(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.comment);

  factory Token.commentEnd(int start) =>
      SimpleToken(start, TokenType.commentEnd);

  factory Token.commentStart(int start) =>
      SimpleToken(start, TokenType.commentStart);

  factory Token.text(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.text);

  factory Token.unexpected(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.unexpected);

  factory Token.eof(int start) => SimpleToken(start, TokenType.eof);

  int get start;

  int get end;

  int get length;

  String get lexeme;

  TokenType get type;

  @override
  int get hashCode => type.hashCode & start & lexeme.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Token &&
      type == other.type &&
      start == other.start &&
      lexeme == other.lexeme;

  @override
  String toString() => '#$type:$start {$lexeme}';
}

abstract class BaseToken implements Token {
  @override
  int get end => start + length;

  @override
  int get length => lexeme.length;

  @override
  String toString() => '#$type:$start:$length {$lexeme}';
}

class SimpleToken extends BaseToken {
  static final Map<TokenType, String> lexemes = <TokenType, String>{
    TokenType.interpolationEnd: '}}',
    TokenType.interpolationStart: '{{',
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
  String get lexeme => lexemes[type];
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
