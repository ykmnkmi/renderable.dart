import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';

void main(List<String> args) {
  final environment = Environment();
  final lexer = Lexer(environment);
  lexer.tokenize('hello {{ name }}!{{ name }}').forEach(print);
}
