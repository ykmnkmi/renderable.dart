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
    text = any()
        .plusLazy(commentStartTag)
        .flatten()
        .map((String lexeme) => Token.text(0, lexeme));

    commentStartTag = string('{#');

    commentStart = (commentStartTag & whitespace().star())
        .pick<String>(0)
        .map((String lexeme) => Token.commentStart(0));

    commentEnd = (whitespace().star() & string('#}'))
        .pick<String>(1)
        .map((String lexeme) => Token.commentEnd(0));

    comment = (commentStart &
            any()
                .starLazy(commentEnd)
                .flatten()
                .map<Token>((String lexeme) => Token.comment(0, lexeme)) &
            commentEnd)
        .castList<Token>();

    root = comment;
    // identifier = (pattern('a-z') & pattern('a-z').star()).flatten();
  }

  Parser<Token> text;
  Parser<String> commentStartTag;
  Parser<Token> commentStart;
  Parser<Token> commentEnd;
  Parser<List<Token>> comment;
  // Parser<String> identifier;
  // Parser<String> expressionStart;
  // Parser<String> expressionEnd;
  // Parser<Token> expression;
  Parser<List<Token>> root;

  List<Token> tokenize(String template) {
    final Result<List<Token>> result = root.parse(template);

    if (result.isFailure) {
      throw result.message;
    }

    return result.value;
  }
}
