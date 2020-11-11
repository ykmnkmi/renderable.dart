library visitor;

import 'nodes.dart';

abstract class Visitor {
  const Visitor();

  void visit(Node node) {
    node.accept(this);
  }

  void visitAll(Iterable<Node> nodes);

  void visitAttribute(Attribute node);

  void visitDictLiteral(DictLiteral node);

  void visitIf(If node);

  void visitItem(Item node);

  void visitListLiteral(ListLiteral node);

  void visitLiteral(Literal node);

  void visitName(Name node);

  void visitOutput(Output node);

  void visitPair(Pair node);

  void visitTest(Test node);

  void visitText(Text node);

  void visitTupleLiteral(TupleLiteral node);

  void visitUnary(Unary node);
}
