import 'package:petitparser/petitparser.dart';
import 'package:renderable/src/lexer.dart' as Lexer show Token, operators;

Lexer.Token Function(Token<String>) token(String type) {
  return (token) => Lexer.Token(token.start, type, token.value);
}

Lexer.Token Function(Token<String>) simpleToken(String type) {
  return (token) => Lexer.Token.simple(token.start, type);
}

void main() {
  final whiteSpaceToken = whitespace().plus().flatten().token().map(simpleToken('whitespace'));

  final $name = (pattern('a-zA-Z') & pattern('a-zA-Z0-9').star()).flatten();
  final nameToken = $name.token().map(token('name'));

  final $sqContent = (pattern("^\\'\n\r") | char('\\') & pattern('\n\r')).flatten();
  final $sq = (char('\'') & $sqContent.star().flatten() & char('\'')).pick(1);
  final $dqContent = (pattern('^\\"\n\r') | char('\\') & pattern('\n\r')).flatten();
  final $dq = (char('"') & $dqContent.star().flatten() & char('"')).pick(1);
  final $string = ($sq | $dq).cast<String>();
  final stringToken = $string.token().map(token('string'));

  final $decimal = digit().plus().flatten();
  final $integer = (($decimal & char('_')).star() & $decimal).flatten();
  final integerToken = $integer.token().map(token('integer'));

  final $float = ($integer & char('.') & $integer & (anyOf('eE') & anyOf('-+').optional() & $integer).optional()).flatten();
  final floatToken = $float.token().map(token('float'));

  final stack = <String>[];

  final $operators = (string('!=') | string('**') | string('//') | string('<=') | string('==') | string('>=') | anyOf('-,;:/()[]{}*/%+<=>|~')).flatten();
  final operatorsToken = $operators.token().map((token) {
    final operator = token.value;

    if (operator == '(') {
      stack.add(')');
    } else if (operator == '[') {
      stack.add(']');
    } else if (operator == '{') {
      stack.add('}');
    } else if (operator == ')' || operator == ']' || operator == '}') {
      final expected = stack.removeLast();

      if (operator != expected) {
        throw 'unexpected char \'$operator\', expected \'$expected\'.';
      }
    }

    return Lexer.Token.simple(token.start, Lexer.operators[operator]!);
  });

  final expression = whiteSpaceToken | nameToken | stringToken | floatToken | integerToken | operatorsToken;

  final variableContent = expression.starLazy(predicate(2, (value) => stack.isEmpty ? value == '}}' : false, 'variable_end expected'));
  final variableBegin = string('{{').token().map(simpleToken('variable_begin'));
  final variableEnd = string('}}').token().map(simpleToken('variable_end'));
  final variable = (variableBegin & variableContent & variableEnd).toList();

  final blockContent = expression.starLazy(predicate(2, (value) => stack.isEmpty ? value == '%}' : false, 'block_end expected'));
  final blockBegin = string('{%').token().map(simpleToken('block_begin'));
  final blockEnd = string('%}').token().map(simpleToken('block_end'));
  final block = (blockBegin & blockContent & blockEnd).toList();

  final data = any().plusLazy(variableBegin | blockBegin).flatten().token().map(token('data'));
  final endData = any().plus().flatten().token().map(token('data'));

  final parser = (data | variable | block | endData).star().toList();

  // TODO: check contains newLine
  print(parser.parse('''hello {{ "nam
  e" }}!'''));
}

extension ToListParserExtension<T> on Parser<List<T>> {
  Parser<List<T>> toList() => ToListParser<T>(this);
}

class ToListParser<T> extends DelegateParser<List<T>> {
  ToListParser(Parser delegate, [this.message]) : super(delegate);

  final String? message;

  @override
  Result<List<T>> parseOn(Context context) {
    final result = delegate.parseOn(context);

    if (result.isSuccess) {
      final list = <T>[];

      for (final value in result.value) {
        if (value is Iterable<T>) {
          list.addAll(value);
        } else if (value is T) {
          list.add(value);
        } else {
          return result.failure(message ?? 'value must be $T or Iterable<$T>');
        }
      }

      return result.success(list);
    }

    return result.failure(result.message);
  }

  @override
  int fastParseOn(String buffer, int position) {
    return delegate.fastParseOn(buffer, position);
  }

  @override
  bool hasEqualProperties(ToListParser<dynamic> other) => super.hasEqualProperties(other);

  @override
  ToListParser<T> copy() => ToListParser<T>(delegate);
}
