library visitor;

import 'ast.dart';

abstract class Visitor {
  const Visitor();

  void visit(Node node) {
    node.accept(this);
  }

  void visitAll(Iterable<Node> nodes);

  void visitDictLiteral(DictLiteral node);

  void visitIf(IfStatement node);

  void visitInterpolation(Interpolation node);

  void visitListLiteral(ListLiteral node);

  void visitLiteral(Literal node);

  void visitName(Name node);

  void visitPair(Pair node);

  void visitText(Text node);

  void visitTupleLiteral(TupleLiteral node);
}
