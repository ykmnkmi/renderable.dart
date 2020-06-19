part of '../ast.dart';

class Interpolation implements Node {
  final List<Node> nodes;

  const Interpolation(this.nodes);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitInterpolation(this, context);
  }

  @override
  String toString() {
    return 'Interpolation ${repr(nodes)}';
  }

  static Node orNode(List<Node> nodes) {
    if (nodes.length == 1) {
      return nodes[0];
    }

    return Interpolation(nodes);
  }
}
