import 'nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  R visitAdd(Add node, [C? context]) {
    return visitBinary(node, context);
  }

  void visitAll(List<Node> nodes, [C? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  R visitAnd(And node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitAttribute(Attribute node, [C? context]);

  R visitBinary(Binary node, [C? context]);

  R visitCall(Call node, [C? context]);

  R visitCompare(Compare node, [C? context]);

  R visitConcat(Concat node, [C? context]);

  R visitCondition(Condition node, [C? context]);

  R visitConstant(Constant<Object?> node, [C? context]);

  R visitData(Data node, [C? context]);

  R visitDictLiteral(DictLiteral node, [C? context]);

  R visitDiv(Div node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitFilter(Filter node, [C? context]);

  R visitFloorDiv(FloorDiv node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitIf(If node, [C? context]);

  R visitItem(Item node, [C? context]);

  R visitKeyword(Keyword node, [C? context]);

  R visitListLiteral(ListLiteral node, [C? context]);

  R visitMod(Mod node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitMul(Mul node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitName(Name node, [C? context]);

  R visitNeg(Neg node, [C? context]) {
    return visitUnary(node, context);
  }

  R visitNot(Not node, [C? context]) {
    return visitUnary(node, context);
  }

  R visitOperand(Operand node, [C? context]);

  R visitOr(Or node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitOutput(Output node, [C? context]);

  R visitPair(Pair node, [C? context]);

  R visitPos(Pos node, [C? context]) {
    return visitUnary(node, context);
  }

  R visitPow(Pow node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitSlice(Slice node, [C? context]);

  R visitSub(Sub node, [C? context]) {
    return visitBinary(node, context);
  }

  R visitTest(Test node, [C? context]);

  R visitTupleLiteral(TupleLiteral node, [C? context]);

  R visitUnary(Unary node, [C? context]);
}
