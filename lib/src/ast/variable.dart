part of '../ast.dart';

class Variable implements Expression {
  const Variable(this.name);

  final String name;

  @override
  void accept(Visitor visitor) {
    return visitor.visitVariable(this);
  }

  @override
  String toString() {
    return 'Variable $name';
  }
}
