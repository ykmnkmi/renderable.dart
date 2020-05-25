part of '../../ast.dart';

class IfStatement extends Statement {
  final Map<Expression, List<Node>> pairs;

  final List<Node> orElse;

  IfStatement(this.pairs, [this.orElse]);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitIf(this);
  }

  @override
  String toString() {
    return 'If ()';
  }
}
