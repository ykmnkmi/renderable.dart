import 'package:petitparser/petitparser.dart';

void main() {
  final exprBegin = string('{{').seq(whitespace().star()).pick<String>(0);
  final exprEnd = whitespace().star().seq(string('}}')).pick<String>(1);
  final name = letter().plus().flatten();
  final expr = exprBegin.seq(name).seq(exprEnd).pick<String>(1);

  final text = any().plusLazy(exprBegin).or(any().plus()).flatten();

  final interpolation = (expr | text);

  print(interpolation.parseOn(Context('hello {{ {{ name }}!', 9)));
}
