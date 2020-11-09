library visitor;

import 'ast.dart';

abstract class Visitor {
  const Visitor();

  void visit(Node node) {
    node.accept(this);
  }

  void visitAll(Iterable<Node> nodes);

  void visitComment(Comment comment);

  void visitIf(IfStatement node);

  void visitInterpolation(Interpolation node);

  void visitLiteral(Literal node);

  void visitText(Text node);

  void visitVariable(Variable node);
}
