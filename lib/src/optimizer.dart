import 'context.dart';
import 'nodes.dart';
import 'utils.dart';
import 'visitor.dart';

class Optimizer extends Visitor<Context, Node?> {
  static Constant<T> constant<T>(CanConstant node, Context? context) {
    // wtf!

    if (node is Constant<T>) {
      return node;
    }

    return Constant<T>(unsafeCast<T>(node.asConstant(context)));
  }

  @override
  Node visitAttribute(Attribute attribute, [Context? context]) {
    return visitExpression(attribute, context);
  }

  @override
  Node visitBinary(Binary binary, [Context? context]) {
    return visitExpression(binary, context);
  }

  @override
  Node visitCall(Call call, [Context? context]) {
    return visitExpression(call, context);
  }

  @override
  Node visitCompare(Compare compare, [Context? context]) {
    return visitExpression(compare, context);
  }

  @override
  Node visitConcat(Concat concat, [Context? context]) {
    return visitExpression(concat, context);
  }

  @override
  Node visitCondition(Condition condition, [Context? context]) {
    return visitExpression(condition, context);
  }

  @override
  Node visitConstant(Constant<Object?> constant, [Context? context]) {
    return visitExpression(constant, context);
  }

  @override
  Node visitData(Data data, [Context? context]) {
    return data;
  }

  @override
  Node visitDictLiteral(DictLiteral dict, [Context? context]) {
    return visitExpression(dict, context);
  }

  Node visitExpression(Expression expression, [Context? context]) {
    return constant(expression, context);
  }

  @override
  Node visitFilter(Filter filter, [Context? context]) {
    return visitExpression(filter, context);
  }

  @override
  Node visitIf(If node, [Context? context]) {
    throw UnimplementedError();
  }

  @override
  Node visitItem(Item item, [Context? context]) {
    return visitExpression(item, context);
  }

  @override
  Node visitKeyword(Keyword node, [Context? context]) {
    throw Impossible();
  }

  @override
  Node visitListLiteral(ListLiteral list, [Context? context]) {
    return visitExpression(list, context);
  }

  @override
  Node visitName(Name name, [Context? context]) {
    return visitExpression(name, context);
  }

  @override
  Node visitOperand(Operand operand, [Context? context]) {
    throw Impossible();
  }

  @override
  Node visitOutput(Output output, [Context? context]) {
    throw UnimplementedError();
  }

  @override
  Node visitPair(Pair pair, [Context? context]) {
    throw UnimplementedError();
  }

  @override
  Node visitSlice(Slice slice, [Context? context]) {
    return visitExpression(slice, context);
  }

  @override
  Node visitTest(Test test, [Context? context]) {
    return visitExpression(test, context);
  }

  @override
  Node visitTupleLiteral(TupleLiteral tuple, [Context? context]) {
    return visitExpression(tuple, context);
  }

  @override
  Node visitUnary(Unary unary, [Context? context]) {
    return visitExpression(unary, context);
  }
}
