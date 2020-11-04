import 'package:renderable/renderable.dart';

const environment = Environment();

void main() {
  final tokens = ExpressionTokenizer(environment).tokenize('null').toList();
  tokens.forEach(print);
  print('');

  final reader = TokenReader(tokens);
  final expression = ExpressionParser(environment).scan(reader);
  print(expression);
}
