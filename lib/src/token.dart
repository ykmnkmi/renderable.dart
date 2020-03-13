part of 'scanner.dart';

enum TokenType {
  comment,
  commentEnd,
  commentStart,
  text,
  whitespace,
  unexpected,
  eof,
}

abstract class Token {
  factory Token.eof(int offset) => SimpleToken(offset, TokenType.eof);

  factory Token.unexpected(int offset, String lexeme) =>
      LexemeToken(offset, lexeme, TokenType.unexpected);

  factory Token.whitespace(int offset, String lexeme) =>
      LexemeToken(offset, lexeme, TokenType.whitespace);

  factory Token.text(int offset, String lexeme) =>
      LexemeToken(offset, lexeme, TokenType.text);

  factory Token.commentStart(int offset) =>
      SimpleToken(offset, TokenType.commentStart);

  factory Token.commentEnd(int offset) =>
      SimpleToken(offset, TokenType.commentEnd);

  factory Token.comment(int offset, String lexeme) =>
      LexemeToken(offset, lexeme, TokenType.comment);

  int get offset;

  int get end;

  int get length;

  String get lexeme;

  TokenType get type;

  @override
  String toString() => 'Token#$offset "$lexeme"';
}

abstract class BaseToken implements Token {
  @override
  int get end => offset + length;

  @override
  int get length => lexeme.length;
}

class SimpleToken extends BaseToken {
  static final Map<TokenType, String> lexemes = <TokenType, String>{
    TokenType.eof: '',
    TokenType.commentStart: '{#',
    TokenType.commentEnd: '#}',
  };

  SimpleToken(this.offset, this.type);

  @override
  final int offset;

  @override
  final TokenType type;

  @override
  String get lexeme => lexemes[type];
}

class LexemeToken extends BaseToken {
  LexemeToken(this.offset, this.lexeme, this.type);

  @override
  final int offset;

  @override
  final String lexeme;

  @override
  final TokenType type;

  @override
  String toString() => '#Token($type) {$offset:$lexeme}';
}
