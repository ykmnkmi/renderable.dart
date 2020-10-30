part of '../../ast.dart';

class Test extends Expression {
  Test(this.name, [this.expr]);

  final String name;

  final Expression expr;

  @override
  void accept(Visitor visitor) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    final buffer = StringBuffer('Test ');

    if (expr != null) {
      buffer.write(expr);
      buffer.write(' is ');
    }

    buffer.write(name);

    return buffer.toString();
  }
}
