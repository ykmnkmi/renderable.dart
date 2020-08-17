part of '../ast.dart';

class Interpolation implements Node {
  const Interpolation(this.nodes);

  final List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitInterpolation(this, context);
  }

  @override
  String toString() {
    return 'Interpolation ${repr(nodes)}';
  }
}
