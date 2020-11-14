import 'package:renderable/renderable.dart';

const environment = Environment();

void main() {
  final tokens = Tokenizer(environment).tokenize('hello {{name }}!').toList();
  tokens.forEach(print);
  print('');

  final reader = TokenReader(tokens);
  final expression = Parser(environment).scan(reader);
  print(expression);
}
