import 'nodes.dart';

abstract class Visitor {
  const Visitor();

  void visitAdd(Add node) {
    visitBinary(node);
  }

  void visitAnd(And node) {
    visitBinary(node);
  }

  void visitAttribute(Attribute node);

  void visitBinary(Binary node);

  void visitCall(Call node);

  void visitCompare(Compare node);

  void visitConcat(Concat node);

  void visitCondition(Condition node);

  void visitConstant(Constant<Object?> node);

  void visitData(Data node);

  void visitDictLiteral(DictLiteral node);

  void visitDiv(Div node) {
    visitBinary(node);
  }

  void visitFilter(Filter node);

  void visitFloorDiv(FloorDiv node) {
    visitBinary(node);
  }

  void visitIf(If node);

  void visitItem(Item node);

  void visitKeyword(Keyword node);

  void visitListLiteral(ListLiteral node);

  void visitMod(Mod node) {
    visitBinary(node);
  }

  void visitMul(Mul node) {
    visitBinary(node);
  }

  void visitName(Name node);

  void visitNeg(Neg node) {
    visitUnary(node);
  }

  void visitNot(Not node) {
    visitUnary(node);
  }

  void visitOperand(Operand node);

  void visitOr(Or node) {
    visitBinary(node);
  }

  void visitOutput(Output node);

  void visitPair(Pair node);

  void visitPos(Pos node) {
    visitUnary(node);
  }

  void visitPow(Pow node) {
    visitBinary(node);
  }

  void visitSlice(Slice node);

  void visitSub(Sub node) {
    visitBinary(node);
  }

  void visitTest(Test node);

  void visitTupleLiteral(TupleLiteral node);

  void visitUnary(Unary node);
}
