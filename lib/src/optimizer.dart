import 'package:meta/meta.dart';

import 'context.dart';
import 'markup.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'utils.dart';
import 'visitor.dart';

class Impossible implements Exception {}

const Optimizer optimizer = Optimizer();

class Optimizer extends Visitor<Context, Node> {
  @literal
  const Optimizer();

  @protected
  Expression constant(Expression expression, [Context? context]) {
    try {
      final value = resolve(expression, context);

      if (value == null) {
        throw Immutable();
      }

      if (value is bool) {
        return Constant<bool>(value);
      }

      if (value is int) {
        return Constant<int>(value);
      }

      if (value is double) {
        return Constant<double>(value);
      }

      if (value is String) {
        return Constant<String>(value);
      }

      return Constant(value);
    } catch (_) {
      return expression;
    }
  }

  @protected
  Expression optimize(Expression expression, [Context? context]) {
    try {
      expression = expression.accept(this, context) as Expression;
      return constant(expression, context);
    } on Impossible {
      return expression;
    }
  }

  @override
  void visitAll(List<Node> nodes, [Context? context]) {
    for (var i = 0; i < nodes.length; i += 1) {
      try {
        if (nodes[i] is Data) {
          continue;
        }

        nodes[i] = nodes[i].accept(this, context);
      } on Impossible {
        // pass
      }
    }
  }

  @override
  Expression visitAttribute(Attribute attribute, [Context? context]) {
    attribute.expression = optimize(attribute.expression, context);
    return constant(attribute, context);
  }

  @override
  Expression visitBinary(Binary binary, [Context? context]) {
    binary.left = optimize(binary.left, context);
    binary.right = optimize(binary.right, context);
    return constant(binary, context);
  }

  @override
  Expression visitCall(Call call, [Context? context]) {
    call.expression = optimize(call.expression, context);
    visitAll(call.arguments);
    visitAll(call.keywordArguments);

    if (call.dArguments != null) {
      call.dArguments = optimize(call.dArguments!, context);
    }

    if (call.dKeywordArguments != null) {
      call.dKeywordArguments = optimize(call.dKeywordArguments!, context);
    }

    return constant(call, context);
  }

  @override
  Expression visitCompare(Compare compare, [Context? context]) {
    compare.expression = optimize(compare.expression, context);
    visitAll(compare.operands, context);
    return constant(compare, context);
  }

  @override
  Expression visitConcat(Concat concat, [Context? context]) {
    return optimize(concat, context);
  }

  @override
  Expression visitCondition(Condition condition, [Context? context]) {
    condition.expression1 = optimize(condition.expression1, context);

    if (condition.expression2 != null) {
      condition.expression2 = optimize(condition.expression2!, context);
    }

    condition.test = optimize(condition.test, context);

    if (boolean(resolve(condition.test, context))) {
      return condition.expression1;
    }

    if (condition.expression2 == null) {
      throw Impossible();
    }

    return condition.expression2!;
  }

  @override
  Constant<dynamic> visitConstant(Constant<dynamic> constant, [Context? context]) {
    return constant;
  }

  @override
  Data visitData(Data data, [Context? context]) {
    if (context!.environment.autoEscape) {
      // TODO: check
      return Data(escape(data.data));
    }

    return data;
  }

  @override
  DictLiteral visitDictLiteral(DictLiteral dict, [Context? context]) {
    visitAll(dict.pairs);
    return dict;
  }

  @override
  Expression visitFilter(Filter filter, [Context? context]) {
    if (!context!.environment.tests.containsKey(filter.name)) {
      throw Impossible();
    }

    filter.expression = optimize(filter.expression, context);
    visitAll(filter.arguments);
    visitAll(filter.keywordArguments);

    if (filter.dArguments != null) {
      filter.dArguments = optimize(filter.dArguments!, context);
    }

    if (filter.dKeywordArguments != null) {
      filter.dKeywordArguments = optimize(filter.dKeywordArguments!, context);
    }

    return constant(filter, context);
  }

  @override
  Node visitFor(For forNode, [Context? context]) {
    forNode.iterable = optimize(forNode.iterable, context);
    visitAll(forNode.body);
    return forNode;
  }

  @override
  Node visitIf(If ifNode, [Context? context]) {
    ifNode.test = optimize(ifNode.test, context);
    visitAll(ifNode.body);

    var next = ifNode.nextIf;

    while (next != null) {
      next.test = optimize(next.test, context);
      visitAll(next.body, context);
      next = next.nextIf;
    }

    if (ifNode.orElse != null) {
      visitAll(ifNode.orElse!, context);
    }

    return ifNode;
  }

  @override
  Expression visitItem(Item item, [Context? context]) {
    item.key = optimize(item.key, context);
    item.expression = optimize(item.expression, context);
    return constant(item, context);
  }

  @override
  Keyword visitKeyword(Keyword keyword, [Context? context]) {
    keyword.value = optimize(keyword.value, context);
    return keyword;
  }

  @override
  ListLiteral visitListLiteral(ListLiteral list, [Context? context]) {
    visitAll(list.expressions);
    return list;
  }

  @override
  Name visitName(Name name, [Context? context]) {
    throw Impossible();
  }

  @override
  Operand visitOperand(Operand operand, [Context? context]) {
    operand.expression = optimize(operand.expression, context);
    return operand;
  }

  @override
  Output visitOutput(Output output, [Context? context]) {
    visitAll(output.nodes, context);
    return output;
  }

  @override
  Pair visitPair(Pair pair, [Context? context]) {
    pair.key = optimize(pair.key, context);
    pair.value = optimize(pair.value, context);
    return pair;
  }

  @override
  Slice visitSlice(Slice slice, [Context? context]) {
    if (slice.start != null) {
      slice.start = optimize(slice.start!, context);
    }

    if (slice.stop != null) {
      slice.stop = optimize(slice.stop!, context);
    }

    if (slice.step != null) {
      slice.step = optimize(slice.step!, context);
    }

    return slice;
  }

  @override
  Expression visitTest(Test test, [Context? context]) {
    if (!context!.environment.tests.containsKey(test.name)) {
      throw Impossible();
    }

    test.expression = optimize(test.expression, context);
    visitAll(test.arguments);
    visitAll(test.keywordArguments);

    if (test.dArguments != null) {
      test.dArguments = optimize(test.dArguments!, context);
    }

    if (test.dKeywordArguments != null) {
      test.dKeywordArguments = optimize(test.dKeywordArguments!, context);
    }

    return constant(test, context);
  }

  @override
  TupleLiteral visitTupleLiteral(TupleLiteral tuple, [Context? context]) {
    visitAll(tuple.expressions);
    return tuple;
  }

  @override
  Expression visitUnary(Unary unary, [Context? context]) {
    unary.expression = optimize(unary.expression, context);
    return constant(unary, context);
  }

  @protected
  static dynamic resolve(Expression expression, [Context? context]) {
    return expression.accept(resolver, context);
  }
}
