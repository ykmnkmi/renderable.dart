import 'package:renderable/renderable.dart';

const environment = Environment();

void main() {
  final tokens = ExpressionTokenizer(environment).tokenize('[1, 2].1').toList();
  tokens.forEach(print);
  print('');

  final reader = TokenReader(tokens);
  final expression = ExpressionParser(environment).scan(reader);
  print(expression);
}
