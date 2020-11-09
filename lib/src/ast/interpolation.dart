part of '../ast.dart';

class Interpolation implements Node {
  const Interpolation(this.children);

  final List<Node> children;

  @override
  accept(Visitor visitor) {
    return visitor.visitInterpolation(this);
  }

  @override
  String toString() {
    return 'Interpolation($children)';
  }
}
