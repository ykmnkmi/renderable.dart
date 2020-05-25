part of '../ast.dart';

class Interpolation extends Statement {
  final List<Node> nodes;

  Interpolation(this.nodes);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitAll(nodes);
  }

  @override
  String toString() {
    return 'Interpolation $nodes';
  }
}
