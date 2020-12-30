import 'dart:math' as math;

import 'context.dart';
import 'filters.dart' as filters;
import 'nodes.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

class Evaluator<C extends Context> extends Visitor<C, dynamic> {
  const Evaluator();

  @override
  void visitAll(List<Node> nodes, [C? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  dynamic visitAttribute(Attribute attribute, [C? context]) {
    return context!.environment.getAttribute(attribute.expression.accept(this, context), attribute.attribute);
  }

  @override
  dynamic visitBinary(Binary binary, [C? context]) {
    final left = binary.left.accept(this, context);
    final right = binary.right.accept(this, context);

    try {
      switch (binary.operator) {
        case '**':
          return math.pow(left as num, right as num);
        case '%':
          return left % right;
        case '//':
          return left ~/ right;
        case '/':
          return left / right;
        case '*':
          return left * right;
        case '-':
          return left - right;
        case '+':
          return left + right;
        case 'or':
          return boolean(left) ? left : right;
        case 'and':
          return boolean(left) ? right : right;
      }
    } on TypeError {
      if (left is int && right is String) {
        return right * left;
      }

      rethrow;
    }
  }

  @override
  dynamic visitCall(Call call, [C? context]) {
    final callable = call.expression.accept(this, context) as Function;
    final arguments = <dynamic>[];

    for (final argument in call.arguments) {
      arguments.add(argument.accept(this, context));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in call.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
    }

    var expression = call.dArguments;

    if (expression != null) {
      arguments.addAll(expression.accept(this, context) as Iterable<dynamic>);
    }

    expression = call.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          (expression.accept(this, context) as Map<String, dynamic>).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return Function.apply(callable, arguments, keywordArguments);
  }

  @override
  dynamic visitCompare(Compare compare, [C? context]) {
    var left = compare.expression.accept(this, context);
    var result = true; // is needed?

    for (final operand in compare.operands) {
      final right = operand.expression.accept(this, context);

      switch (operand.operator) {
        case 'eq':
          result = result && tests.equal(left, right);
          break;
        case 'ne':
          result = result && tests.notEqual(left, right);
          break;
        case 'lt':
          result = result && tests.lessThan(left, right);
          break;
        case 'le':
          result = result && tests.lessThanOrEqual(left, right);
          break;
        case 'gt':
          result = result && tests.greaterThan(left, right);
          break;
        case 'ge':
          result = result && tests.greaterThanOrEqual(left, right);
          break;
        case 'in':
          result = result && tests.contains(left, right);
          break;
        case 'notin':
          result = result && !tests.contains(left, right);
          break;
      }

      if (!result) {
        return false;
      }

      left = right;
    }

    return result;
  }

  @override
  String visitConcat(Concat concat, [C? context]) {
    final buffer = StringBuffer();

    for (final expression in concat.expressions) {
      buffer.write(expression.accept(this, context));
    }

    return buffer.toString();
  }

  @override
  dynamic visitCondition(Condition condition, [C? context]) {
    if (boolean(condition.test.accept(this, context))) {
      return condition.expression1.accept(this, context);
    }

    final expression = condition.expression2;

    if (expression != null) {
      return expression.accept(this, context);
    }

    return null;
  }

  @override
  dynamic visitConstant(Constant<dynamic> constant, [C? context]) {
    return constant.value;
  }

  @override
  String visitData(Data data, [C? context]) {
    return data.data;
  }

  @override
  Map<dynamic, dynamic> visitDictLiteral(DictLiteral dict, [C? context]) {
    final result = <dynamic, dynamic>{};

    for (final pair in dict.pairs) {
      result[pair.key.accept(this, context)] = pair.value.accept(this, context);
    }

    return result;
  }

  @override
  dynamic visitFilter(Filter filter, [C? context]) {
    final arguments = <dynamic>[];

    for (final argument in filter.arguments) {
      arguments.add(argument.accept(this, context));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in filter.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
    }

    var expression = filter.dArguments;

    if (expression != null) {
      arguments.addAll(expression.accept(this, context) as Iterable<dynamic>);
    }

    expression = filter.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          (expression.accept(this, context) as Map<String, dynamic>).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return context!.environment
        .callFilter(filter.name, filter.expression.accept(this, context), arguments: arguments, keywordArguments: keywordArguments, context: context);
  }

  @override
  void visitIf(If node, [C? context]) {
    if (boolean(node.test.accept(this, context))) {
      visitAll(node.body, context);
      return;
    }

    if (node.elseIf.isNotEmpty) {
      for (final ifNode in node.elseIf) {
        if (boolean(ifNode.test.accept(this, context))) {
          visitAll(ifNode.body, context);
          return;
        }
      }
    }

    if (node.else_.isNotEmpty) {
      visitAll(node.else_, context);
      return;
    }
  }

  @override
  dynamic visitItem(Item item, [C? context]) {
    return context!.environment.getItem(item.expression.accept(this, context), item.key.accept(this, context));
  }

  @override
  MapEntry<Symbol, dynamic> visitKeyword(Keyword keyword, [C? context]) {
    return MapEntry<Symbol, dynamic>(Symbol(keyword.key), keyword.value.accept(this, context));
  }

  @override
  List<dynamic> visitListLiteral(ListLiteral list, [C? context]) {
    final result = <dynamic>[];

    for (final node in list.expressions) {
      result.add(node.accept(this, context));
    }

    return result;
  }

  @override
  dynamic visitName(Name name, [C? context]) {
    return context!.get(name.name);
  }

  @override
  dynamic visitOperand(Operand oprand, [C? context]) {
    return <dynamic>[oprand.operator, oprand.expression.accept(this, context)];
  }

  @override
  dynamic visitOutput(Output output, [C? context]) {
    final result = <dynamic>[];

    for (final node in output.nodes) {
      if (node is Data) {
        result.add(node.accept(this, context));
      } else {
        result.add(context!.environment.finalize(node.accept(this, context)));
      }
    }

    return result;
  }

  @override
  MapEntry<dynamic, dynamic> visitPair(Pair pair, [C? context]) {
    return MapEntry<dynamic, dynamic>(pair.key.accept(this, context), pair.value.accept(this, context));
  }

  @override
  dynamic visitSlice(Slice $slice, [C? context]) {
    final value = $slice.expression.accept(this, context);
    final start = $slice.start.accept(this, context) as int;

    var expression = $slice.stop;
    int stop;

    if (expression != null) {
      stop = math.min(filters.count(value), expression.accept(this, context) as int);
    } else {
      stop = value.length as int;
    }

    expression = $slice.step;
    int step;

    if (expression != null) {
      step = expression.accept(this, context) as int;
    } else {
      step = 1;
    }

    return slice(value, start, stop, step);
  }

  @override
  dynamic visitTest(Test test, [C? context]) {
    final arguments = <dynamic>[];

    for (final argument in test.arguments) {
      arguments.add(argument.accept(this, context));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in test.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
    }

    var expression = test.dArguments;

    if (expression != null) {
      arguments.addAll(expression.accept(this, context) as Iterable<dynamic>);
    }

    expression = test.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          (expression.accept(this, context) as Map<String, dynamic>).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return context!.environment.callTest(test.name, test.expression.accept(this, context), arguments: arguments, keywordArguments: keywordArguments);
  }

  @override
  List<dynamic> visitTupleLiteral(TupleLiteral tuple, [C? context]) {
    final result = <dynamic>[];

    for (final node in tuple.expressions) {
      result.add(node.accept(this, context));
    }

    return result;
  }

  @override
  dynamic visitUnary(Unary unaru, [C? context]) {
    final value = unaru.expression.accept(this, context);

    switch (unaru.operator) {
      case '+':
        return value as num;
      case '-':
        return -(value as num);
      case 'not':
        return !boolean(value);
    }
  }
}
