import 'nodes.dart';

abstract class Visitor<R> {
  const Visitor();

  R visitAdd(Add node) {
    return visitBinary(node);
  }

  R visitAnd(And node) {
    return visitBinary(node);
  }

  R visitAttribute(Attribute node);

  R visitBinary(Binary node);

  R visitCall(Call node);

  R visitCompare(Compare node);

  R visitConcat(Concat node);

  R visitCondition(Condition node);

  R visitConstant(Constant<Object?> node);

  R visitData(Data node);

  R visitDictLiteral(DictLiteral node);

  R visitDiv(Div node) {
    return visitBinary(node);
  }

  R visitFilter(Filter node);

  R visitFloorDiv(FloorDiv node) {
    return visitBinary(node);
  }

  R visitIf(If node);

  R visitItem(Item node);

  R visitKeyword(Keyword node);

  R visitListLiteral(ListLiteral node);

  R visitMod(Mod node) {
    return visitBinary(node);
  }

  R visitMul(Mul node) {
    return visitBinary(node);
  }

  R visitName(Name node);

  R visitNeg(Neg node) {
    return visitUnary(node);
  }

  R visitNot(Not node) {
    return visitUnary(node);
  }

  R visitOperand(Operand node);

  R visitOr(Or node) {
    return visitBinary(node);
  }

  R visitOutput(Output node);

  R visitPair(Pair node);

  R visitPos(Pos node) {
    return visitUnary(node);
  }

  R visitPow(Pow node) {
    return visitBinary(node);
  }

  R visitSlice(Slice node);

  R visitSub(Sub node) {
    return visitBinary(node);
  }

  R visitTest(Test node);

  R visitTupleLiteral(TupleLiteral node);

  R visitUnary(Unary node);
}
