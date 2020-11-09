part of '../ast.dart';

class Literal<T> implements Expression {
  const Literal(this.value);

  final T value;

  @override
  void accept(Visitor visitor) {
    return visitor.visitLiteral(this);
  }

  @override
  String toString() {
    return 'Literal<$T>($value)';
  }
}
