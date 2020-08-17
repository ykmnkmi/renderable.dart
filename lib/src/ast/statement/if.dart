part of '../../ast.dart';

class IfStatement extends Statement {
  IfStatement(this.pairs, [this.orElse]);

  final Map<Expression, Node> pairs;

  final Node orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitIf(this, context);
  }

  @override
  String toString() {
    return 'If';
  }
}
