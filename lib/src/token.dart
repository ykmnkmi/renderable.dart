part of 'tokenizer.dart';

enum TokenType {
  commentStart,
  commentEnd,
  comment,
  expressionStart,
  expressionEnd,
  identifier,
  statementStart,
  statementEnd,
  space,
  keyword,
  text,
  error,
}

abstract class Token {
  factory Token.commentStart(int start) =>
      SimpleToken(start, TokenType.commentStart);

  factory Token.commentEnd(int start) =>
      SimpleToken(start, TokenType.commentEnd);

  factory Token.comment(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.comment);

  factory Token.expressionStart(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.expressionStart);

  factory Token.expressionEnd(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.expressionEnd);

  factory Token.identifier(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.identifier);

  factory Token.statementStart(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.statementStart);

  factory Token.statementEnd(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.statementEnd);

  factory Token.space(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.space);

  factory Token.keyword(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.keyword);

  factory Token.text(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.text);
  
  factory Token.error(int start, String lexeme) =>
      LexemeToken(start, lexeme, TokenType.error);

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
    TokenType.commentEnd: '#}',
    TokenType.commentStart: '{#',
    TokenType.expressionEnd: '}}',
    TokenType.expressionStart: '{{',
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
