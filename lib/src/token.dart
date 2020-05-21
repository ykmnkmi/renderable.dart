part of 'tokenizer.dart';

@immutable
abstract class BaseToken implements Token {
  @override
  int get end => start + length;

  @override
  int get length => lexeme.length;

  @override
  String toString() => '#$type:$start:$length {$lexeme}';
}

class LexemeToken extends BaseToken {
  @override
  final int start;

  @override
  final String lexeme;

  @override
  final TokenType type;

  LexemeToken(this.start, this.lexeme, this.type);
}

class SimpleToken extends BaseToken {
  static final Map<TokenType, String> lexemes = <TokenType, String>{
    TokenType.statementStart: '{%',
    TokenType.statementEnd: '%}',
    TokenType.expressionStart: '{{',
    TokenType.expressionEnd: '}}',
    TokenType.space: ' ',
    TokenType.commentStart: '{#',
    TokenType.commentEnd: '#}',
  };

  @override
  final int start;

  @override
  final TokenType type;

  SimpleToken(this.start, this.type);

  @override
  String get lexeme => lexemes[type];
}

abstract class Token {
  factory Token(int start, String lexeme, TokenType type) = LexemeToken;

  factory Token.simple(int start, TokenType type) = SimpleToken;

  int get end;

  @override
  int get hashCode => type.hashCode & start & lexeme.hashCode;

  int get length;

  String get lexeme;

  int get start;

  TokenType get type;

  @override
  bool? operator ==(Object? other) =>
      other is Token && type == other.type && start == other.start && lexeme == other.lexeme;

  @override
  String toString() => '#$type:$start {$lexeme}';
}

enum TokenType {
  statementStart,
  statementEnd,
  expressionStart,
  expressionEnd,
  word,
  space,
  commentStart,
  commentEnd,
  comment,
  text,
  error,
}
