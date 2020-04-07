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
  factory Token(int start, String lexeme, TokenType type) => LexemeToken(start, lexeme, type);

  factory Token.simple(int start, TokenType type) => SimpleToken(start, type);

  int get start;

  int get end;

  int get length;

  String get lexeme;

  TokenType get type;

  @override
  int get hashCode => type.hashCode & start & lexeme.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Token && type == other.type && start == other.start && lexeme == other.lexeme;

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
    TokenType.commentStart: '{#',
    TokenType.commentEnd: '#}',
    TokenType.expressionStart: '{{',
    TokenType.expressionEnd: '}}',
    TokenType.space: ' ',
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
