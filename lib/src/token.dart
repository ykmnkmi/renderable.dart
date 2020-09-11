part of 'tokenizer.dart';

abstract class Token {
  const factory Token(int start, TokenType type,String lexeme) = LexemeToken;

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
    return other is Token && type == other.type && start == other.start && value == other.value;
  }

  bool same(Token other);

  @override
  String toString() {
    return '#$type:$start $value';
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
  static final Map<TokenType, String> lexemes = <TokenType, String>{
    TokenType.space: ' ',
  };

  const SimpleToken(this.start, this.type);

  @override
  final int start;

  @override
  final TokenType type;

  @override
  String get value {
    return lexemes[type];
  }
}
