part of '../ast.dart';

class Interpolation implements Node {
  const Interpolation(this.children);

  final List<Node> children;

  @override
  void accept(Visitor visitor) {
    visitor.visitInterpolation(this);
  }

  @override
  String toString() {
    return 'Interpolation($children)';
  }
}
