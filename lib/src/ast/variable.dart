part of '../ast.dart';

class Variable implements Expression {
  final String name;

  const Variable(this.name);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitVariable(this, context);
  }

  @override
  String toString() {
    return 'Variable $name';
  }
}
