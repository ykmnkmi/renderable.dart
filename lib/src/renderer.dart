import 'dart:math' as math;

import 'context.dart';
import 'enirvonment.dart';
import 'filters.dart' as filters;
import 'nodes.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink, [Map<String, dynamic>? context]) : super(environment, context);

  final StringSink sink;
}

class Renderer extends Visitor<RenderContext, dynamic> {
  const Renderer();

  @override
  void visitAll(List<Node> nodes, RenderContext context) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  dynamic visitAttribute(Attribute attribute, RenderContext context) {
    return context.environment.getAttribute(attribute.expression.accept(this, context), attribute.attribute);
  }

  @override
  dynamic visitBinary(Binary binary, RenderContext context) {
    final left = binary.left.accept(this, context);
    final right = binary.right.accept(this, context);

    try {
      switch (binary.operator) {
        case '**':
          return math.pow(unsafeCast<num>(left), unsafeCast<num>(right));
        case '%':
          return unsafeCast<num>(left) % unsafeCast<num>(right);
        case '//':
          return unsafeCast<num>(left) ~/ unsafeCast<num>(right);
        case '/':
          return unsafeCast<num>(left) / unsafeCast<num>(right);
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
  dynamic visitCall(Call call, RenderContext context) {
    final callable = unsafeCast<Function>(call.expression.accept(this, context));
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
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this, context)));
    }

    expression = call.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(unsafeCast<Map<String, dynamic>>(expression.accept(this, context))
          .map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return Function.apply(callable, arguments, keywordArguments);
  }

  @override
  dynamic visitCompare(Compare compare, RenderContext context) {
    var left = compare.expression.accept(this, context);
    var result = true;

    for (final operand in compare.operands) {
      if (!result) {
        return false;
      }

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

      left = right;
    }

    return result;
  }

  @override
  dynamic visitConcat(Concat concat, RenderContext context) {
    final buffer = StringBuffer();

    for (final expression in concat.expressions) {
      buffer.write(expression.accept(this, context));
    }

    return buffer.toString();
  }

  @override
  dynamic visitCondition(Condition condition, RenderContext context) {
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
  dynamic visitConstant(Constant<dynamic> constant, RenderContext context) {
    return constant.value;
  }

  @override
  void visitData(Data data, RenderContext context) {
    context.sink.write(data.data);
  }

  @override
  dynamic visitDictLiteral(DictLiteral dict, RenderContext context) {
    final result = <dynamic, dynamic>{};

    for (final pair in dict.pairs) {
      result[pair.key.accept(this, context)] = pair.value.accept(this, context);
    }

    return result;
  }

  @override
  dynamic visitFilter(Filter filter, RenderContext context) {
    final arguments = <dynamic>[filter.expression.accept(this, context)];

    for (final argument in filter.arguments) {
      arguments.add(argument.accept(this, context));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in filter.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
    }

    var expression = filter.dArguments;

    if (expression != null) {
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this, context)));
    }

    expression = filter.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(unsafeCast<Map<String, dynamic>>(expression.accept(this, context))
          .map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return context.environment.callFilter(filter.name, arguments, keywordArguments);
  }

  @override
  void visitIf(If node, RenderContext context) {
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
    }
  }

  @override
  dynamic visitItem(Item item, RenderContext context) {
    return context.environment.getItem(item.expression.accept(this, context), item.key.accept(this, context));
  }

  @override
  MapEntry<Symbol, dynamic> visitKeyword(Keyword keyword, RenderContext context) {
    return MapEntry<Symbol, dynamic>(Symbol(keyword.key), keyword.value.accept(this, context));
  }

  @override
  dynamic visitListLiteral(ListLiteral list, RenderContext context) {
    final result = <dynamic>[];

    for (final node in list.nodes) {
      result.add(node.accept(this, context));
    }

    return result;
  }

  @override
  dynamic visitName(Name name, RenderContext context) {
    return context.get(name.name);
  }

  @override
  List<dynamic> visitOperand(Operand oprand, RenderContext context) {
    return [oprand.operator, oprand.expression.accept(this, context)];
  }

  @override
  void visitOutput(Output output, RenderContext context) {
    for (final node in output.nodes) {
      if (node is Data) {
        node.accept(this, context);
      } else {
        context.sink.write(context.environment.finalize(node.accept(this, context)));
      }
    }
  }

  @override
  dynamic visitPair(Pair pair, RenderContext context) {
    return MapEntry<dynamic, dynamic>(pair.key.accept(this, context), pair.value.accept(this, context));
  }

  @override
  dynamic visitSlice(Slice slice_, RenderContext context) {
    final value = slice_.expression.accept(this, context);
    final start = unsafeCast<int>(slice_.start.accept(this, context));

    var expression = slice_.stop;
    int? stop;

    if (expression != null) {
      stop = math.min(filters.count(value), unsafeCast<int>(expression.accept(this, context)));
    } else {
      stop = value.length;
    }

    expression = slice_.step;
    int? step;

    if (expression != null) {
      step = unsafeCast<int>(expression.accept(this, context));
    }

    if (value is String) {
      return sliceString(value, start, stop, step);
    }

    return slice(value, start, stop, step);
  }

  @override
  dynamic visitTest(Test test, RenderContext context) {
    final arguments = <dynamic>[test.expression.accept(this, context)];

    for (final argument in test.arguments) {
      arguments.add(argument.accept(this, context));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in test.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
    }

    var expression = test.dArguments;

    if (expression != null) {
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this, context)));
    }

    expression = test.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(unsafeCast<Map<String, dynamic>>(expression.accept(this, context))
          .map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return context.environment.callTest(test.name, arguments, keywordArguments);
  }

  @override
  dynamic visitTupleLiteral(TupleLiteral tuple, RenderContext context) {
    final result = <dynamic>[];

    for (final node in tuple.nodes) {
      result.add(node.accept(this, context));
    }

    return result;
  }

  @override
  dynamic visitUnary(Unary unaru, RenderContext context) {
    final value = unaru.expression.accept(this, context);

    switch (unaru.operator) {
      case '+':
        return 0 + unsafeCast<num>(value);
      case '-':
        return 0 - unsafeCast<num>(value);
      case 'not':
        return !boolean(value);
    }
  }
}
