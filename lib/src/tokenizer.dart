part of 'scanner.dart';

class Tokenizer {
  static Tokenizer _instance;

  static Tokenizer Function() _factory = () {
    _instance = Tokenizer._();
    _factory = () => _instance;
    return _instance;
  };

  factory Tokenizer() => _factory();

  Tokenizer._() {
    commentStartTag = (string('{#') & whitespace().star()).pick<String>(0);
    commentEndTag = (whitespace().star() & string('#}')).pick<String>(1);

    commentStart = commentStartTag.mapWithOffset<Token>(
        (int offset, String lexeme) => Token.commentStart(offset));
    commentEnd = commentEndTag.mapWithOffset<Token>(
        (int offset, String lexeme) => Token.commentEnd(offset));

    comment = (commentStart &
            (any().starLazy(commentEndTag) | any().star())
                .flatten()
                .mapWithOffset<Token>((int offset, String lexeme) =>
                    Token.comment(offset, lexeme)) &
            commentEnd)
        .castList<Token>();

    text = (any().plusLazy(commentStartTag) | any().plus())
        .flatten()
        .mapWithOffset<Token>(
            (int offset, String lexeme) => Token.text(offset, lexeme));

    root = (comment | text).plus();
    // identifier = (pattern('a-z') & pattern('a-z').star()).flatten();
  }

  Parser<String> commentStartTag;
  Parser<Token> commentStart;
  Parser<String> commentEndTag;
  Parser<Token> commentEnd;
  Parser<List<Token>> comment;
  Parser<Token> text;
  // Parser<String> identifier;
  // Parser<String> expressionStart;
  // Parser<String> expressionEnd;
  // Parser<Token> expression;
  Parser<List<Object>> root;

  Iterable<Token> tokenize(String template) sync* {
    final Result<List<Object>> result = root.parse(template);

    if (result.isFailure) {
      throw result.message;
    }

    for (Object value in result.value) {
      if (value is Token) {
        yield value;
      } else if (value is Iterable<Object>) {
        for (Object object in value) {
          if (object is Iterable<Token>) {
            yield* object;
          } else if (object is Token) {
            yield object;
          } else {
            throw TypeError();
          }
        }
      } else {
        throw TypeError();
      }
    }
  }
}
