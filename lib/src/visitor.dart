import 'nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  R visitAdd(Add add, [C? context]) {
    return visitBinary(add, context);
  }

  void visitAll(List<Node> nodes, [C? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  R visitAnd(And and, [C? context]) {
    return visitBinary(and, context);
  }

  R visitAssign(Assign assign, [C? context]);

  R visitAssignBlock(AssignBlock assign, [C? context]);

  R visitAttribute(Attribute attribute, [C? context]);

  R visitBinary(Binary binary, [C? context]);

  R visitCall(Call call, [C? context]);

  R visitCompare(Compare compare, [C? context]);

  R visitConcat(Concat concat, [C? context]);

  R visitCondition(Condition condition, [C? context]);

  R visitConstant(Constant<Object?> constant, [C? context]);

  R visitData(Data data, [C? context]);

  R visitDictLiteral(DictLiteral dict, [C? context]);

  R visitDiv(Div div, [C? context]) {
    return visitBinary(div, context);
  }

  R visitFilter(Filter filter, [C? context]);

  R visitFloorDiv(FloorDiv floorDiv, [C? context]) {
    return visitBinary(floorDiv, context);
  }

  R visitFor(For forNode, [C? context]);

  R visitIf(If ifNode, [C? context]);

  R visitItem(Item item, [C? context]);

  R visitKeyword(Keyword keyword, [C? context]);

  R visitListLiteral(ListLiteral list, [C? context]);

  R visitMod(Mod mod, [C? context]) {
    return visitBinary(mod, context);
  }

  R visitMul(Mul mul, [C? context]) {
    return visitBinary(mul, context);
  }

  R visitName(Name name, [C? context]);

  R visitNamespaceReference(NamespaceReference reference, [C? context]);

  R visitNeg(Neg neg, [C? context]) {
    return visitUnary(neg, context);
  }

  R visitNot(Not not, [C? context]) {
    return visitUnary(not, context);
  }

  R visitOperand(Operand operand, [C? context]);

  R visitOr(Or or, [C? context]) {
    return visitBinary(or, context);
  }

  R visitOutput(Output output, [C? context]);

  R visitPair(Pair pair, [C? context]);

  R visitPos(Pos pos, [C? context]) {
    return visitUnary(pos, context);
  }

  R visitPow(Pow pow, [C? context]) {
    return visitBinary(pow, context);
  }

  R visitSlice(Slice slice, [C? context]);

  R visitSub(Sub sub, [C? context]) {
    return visitBinary(sub, context);
  }

  R visitTest(Test test, [C? context]);

  R visitTupleLiteral(TupleLiteral tuple, [C? context]);

  R visitUnary(Unary unary, [C? context]);

  R visitWith(With wiz, [C? context]);
}
