library visitor;

import 'nodes.dart';

abstract class Visitor {
  const Visitor();

  void visitAll(Iterable<Node> nodes);

  void visitAttribute(Attribute node);

  void visitBinary(Binary node);

  void visitCall(Call node);

  void visitCompare(Compare node);

  void visitConcat(Concat node);

  void visitCondition(Condition node);

  void visitConstant(Constant<Object> node);

  void visitData(Data node);

  void visitDictLiteral(DictLiteral node);

  void visitFilter(Filter node);

  void visitIf(If node);

  void visitItem(Item node);

  void visitKeyword(Keyword node);

  void visitListLiteral(ListLiteral node);

  void visitName(Name node);

  void visitOperand(Operand node);

  void visitOutput(Output node);

  void visitPair(Pair node);

  void visitSlice(Slice node);

  void visitTest(Test node);

  void visitTupleLiteral(TupleLiteral node);

  void visitUnary(Unary node);
}
