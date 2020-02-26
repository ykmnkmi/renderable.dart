// abstract class Token {
//   // factory Token.whitespace(int offset, String lexeme) => LexemeToken.whitespace(offset, lexeme);

//   factory Token.unexpected(int offset, String lexeme) => LexemeToken(offset, lexeme, TokenType.unexpected);

//   factory Token.eof(int offset) => SimpleToken(offset, TokenType.eof);

//   int get offset;

//   int get end;

//   int get length;

//   String get lexeme;

//   TokenType get type;

//   @override
//   String toString() => 'Token#$offset "$lexeme"';
// }

// abstract class BaseToken implements Token {
//   @override
//   int get end => offset + length;

//   @override
//   int get length => lexeme.length;
// }

// class SimpleToken extends BaseToken {
//   static final Map<TokenType, String> lexemes = <TokenType, String>{
//     TokenType.eof: '',
//   };

//   SimpleToken(this.offset, this.type);

//   @override
//   final int offset;

//   @override
//   final TokenType type;

//   @override
//   String get lexeme => lexemes[type];
// }

// class LexemeToken extends BaseToken {
//   // factory LexemeToken.whitespace(int offset, String lexeme) => LexemeToken(offset, lexeme, TokenType.whitespace);

//   LexemeToken(this.offset, this.lexeme, this.type);

//   @override
//   final int offset;

//   @override
//   final String lexeme;

//   @override
//   final TokenType type;
// }
