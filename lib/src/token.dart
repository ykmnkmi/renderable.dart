part of 'tokenizer.dart';

@immutable
abstract class BaseToken implements Token {
  const BaseToken();

  @override
  int get end => start + length;

  @override
  int get length => value.length;

  @override
  bool same(Token other) {
    return type == other.type && value == other.value;
  }

  @override
  String toString() {
    return '#$type:$start:$length ${repr(value)}';
  }
}

class LexemeToken extends BaseToken {
  @override
  final int start;

  @override
  final String value;

  @override
  final TokenType type;

  const LexemeToken(this.start, this.value, this.type);
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

  const SimpleToken(this.start, this.type);

  @override
  String get value {
    return lexemes[type];
  }
}

abstract class Token {
  const factory Token(int start, String lexeme, TokenType type) = LexemeToken;

  const factory Token.simple(int start, TokenType type) = SimpleToken;

  int get end;

  @override
  int get hashCode {
    return type.hashCode & start & value.hashCode;
  }

  int get length;

  int get start;

  TokenType get type;

  String get value;

  @override
  bool operator ==(Object other) {
    return other is Token && type == other.type && start == other.start && value == other.value;
  }

  bool same(Token other);

  @override
  String toString() {
    return '#$type:$start ${repr(value)}';
  }
}

enum TokenType {
  statementStart,
  statementEnd,
  expressionStart,
  expressionEnd,
  identifier,
  space,
  commentStart,
  commentEnd,
  comment,
  text,
  error,
}
