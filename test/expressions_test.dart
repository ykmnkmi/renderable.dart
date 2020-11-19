import 'package:renderable/renderable.dart';

const environment = Environment();

void main() {
  final tokens = Tokenizer(environment).tokenize('hello {{ user.name | lower }}!').toList();
  tokens.forEach(print);
  print('');

  final reader = TokenReader(tokens);
  final node = Parser(environment).scan(reader);
  print(node);
}
