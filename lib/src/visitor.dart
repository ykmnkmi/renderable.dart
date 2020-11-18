library visitor;

import 'nodes.dart';

abstract class Visitor {
  const Visitor();

  void visit(Node node);

  void visitAll(Iterable<Node> nodes);

  void visitAttribute(Attribute node);

  void visitCall(Call node);

  void visitData(Data node);

  void visitDictLiteral(DictLiteral node);

  void visitFilter(Filter node);
  
  void visitIf(If node);

  void visitItem(Item node);

  void visitKeyword(Keyword node);

  void visitListLiteral(ListLiteral node);

  void visitLiteral(Literal node);

  void visitName(Name node);

  void visitOutput(Output node);

  void visitPair(Pair node);

  void visitSlice(Slice node);

  void visitTest(Test node);

  void visitTupleLiteral(TupleLiteral node);

  void visitUnary(Unary node);
}
