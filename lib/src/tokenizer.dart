library tokenizer;

import 'package:petitparser/petitparser.dart' hide Token;

part 'tokenizer/petitparser_ext.dart';
part 'tokenizer/token.dart';

enum TagType {
  trim,
  keep,
}

class Tokenizer {
  static Tokenizer _instance;

  static Tokenizer Function() _factory = () {
    _instance = Tokenizer._();
    _factory = () => _instance;
    return _instance;
  };

  factory Tokenizer() => _factory();

  Tokenizer._() {
    // comment

    commentStartTag = (string('{#') & whitespace().star()).pick<String>(0);
    commentEndTag = (whitespace().star() & string('#}')).pick<String>(1);

    commentStart = commentStartTag.mapWithStart<Token>(
        (int offset, String lexeme) => Token.commentStart(offset));
    commentEnd = commentEndTag.mapWithStart<Token>(
        (int offset, String lexeme) => Token.commentEnd(offset));

    comment = (commentStart &
            (any().starLazy(commentEndTag) | any().star())
                .flatten()
                .mapWithStart<Token>((int offset, String lexeme) =>
                    Token.comment(offset, lexeme)) &
            commentEnd)
        .castList<Token>();

    // expression

    interpolationStartTag =
        (((whitespace().star() & string('{{') & pattern('-')) |
                        (string('{{') & pattern('+').optional()))
                    .flatten() &
                whitespace().star())
            .pick<String>(0);
    interpolationEndTag = (whitespace().star() &
            (pattern('+-').optional() & string('}}')).flatten())
        .pick<String>(1);

    interpolationStart = interpolationStartTag.mapWithStart<Token>(
        (int offset, String lexeme) =>
            Token.interpolationStart(offset, lexeme));
    interpolationEnd = interpolationEndTag.mapWithStart<Token>(
        (int offset, String lexeme) => Token.interpolationEnd(offset, lexeme));

    identifier = letter().plus().flatten().mapWithStart<Token>(
        (int offset, String lexeme) => Token.identifier(offset, lexeme));
    spaces = whitespace().plus().flatten().mapWithStart<Token>(
        (int offset, String lexeme) => Token.whitespace(offset, lexeme));
    interpolationBody =
        (identifier | spaces).plusLazy(interpolationEndTag).castList<Token>();

    interpolation = (interpolationStart & interpolationBody & interpolationEnd)
        .map<List<Token>>((List<Object> values) => (values[1] as List<Token>)
          ..insert(0, values[0] as Token)
          ..add(values[2] as Token));

    // text

    text =
        (any().plusLazy(interpolationStartTag | commentStartTag) | any().plus())
            .flatten()
            .mapWithStart<Token>(
                (int offset, String lexeme) => Token.text(offset, lexeme));

    // template

    root = (interpolation | comment | text).star().end();
  }

  Parser<Token> text;

  Parser<String> commentStartTag;
  Parser<String> commentEndTag;
  Parser<Token> commentStart;
  Parser<Token> commentEnd;
  Parser<List<Token>> comment;

  Parser<String> interpolationStartTag;
  Parser<String> interpolationEndTag;
  Parser<Token> interpolationStart;
  Parser<Token> interpolationEnd;

  Parser<Token> spaces;
  Parser<Token> identifier;
  Parser<List<Token>> interpolationBody;

  Parser<List<Token>> interpolation;

  Parser<List<Object>> root;

  Iterable<Token> tokenize(String template) sync* {
    final Result<List<Object>> result = root.parse(template);

    if (result.isFailure) {
      throw result.message;
    }

    for (Object value in result.value) {
      if (value is Token) {
        yield value;
      } else if (value is Iterable<Token>) {
        yield* value;
      } else {
        throw Exception('token or token collection expected.');
      }
    }
  }
}
