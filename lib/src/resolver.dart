import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'nodes.dart';
import 'runtime.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

const ExpressionResolver resolver = ExpressionResolver();

class ExpressionResolver<C extends Context> extends Visitor<C, Object?> {
  @literal
  const ExpressionResolver();

  @protected // update
  T Function(T Function(List<Object?>, Map<Symbol, Object?>)) callable<T>(Callable callable, [C? context]) {
    final positional = <Object?>[];

    if (callable.arguments != null) {
      for (final argument in callable.arguments!) {
        positional.add(argument.accept(this, context));
      }
    }

    final named = <Symbol, Object?>{};

    if (callable.keywordArguments != null) {
      for (final keywordArgument in callable.keywordArguments!) {
        named[symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
      }
    }
    if (callable.dArguments != null) {
      positional.addAll(callable.dArguments!.accept(this, context) as Iterable<Object?>);
    }

    if (callable.dKeywordArguments != null) {
      named.addAll((callable.dKeywordArguments!.accept(this, context) as Map<Object?, Object?>)
          .cast<String, Object?>()
          .map<Symbol, Object?>((key, value) => MapEntry<Symbol, Object?>(symbol(key), value)));
    }

    return (T Function(List<Object?> positional, Map<Symbol, Object?> named) callback) => callback(positional, named);
  }

  @protected
  Object? callFilter(Filter filter, [Object? value, C? context]) {
    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context!.environment.callFilter(filter.name, value, positional: positional, named: named);
    }

    return callable<Object?>(filter, context)(callback);
  }

  @protected
  bool callTest(Test test, [Object? value, C? context]) {
    bool callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context!.environment.callTest(test.name, value, positional: positional, named: named);
    }

    return callable<bool>(test, context)(callback);
  }

  @override
  void visitAll(List<Node> nodes, [C? context]) {
    throw UnimplementedError();
  }

  @override
  void visitAssign(Assign assign, [C? context]) {
    throw UnimplementedError();
  }

  @override
  void visitAssignBlock(AssignBlock assign, [C? context]) {
    throw UnimplementedError();
  }

  @override
  Object? visitAttribute(Attribute attribute, [C? context]) {
    return context!.environment.getAttribute(attribute.expression.accept(this, context)!, attribute.attribute);
  }

  @override
  Object? visitBinary(Binary binary, [C? context]) {
    final dynamic left = binary.left.accept(this, context);
    final dynamic right = binary.right.accept(this, context);

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
          return boolean(left) ? right : left;
      }
    } on TypeError {
      if (left is int && right is String) {
        return right * left;
      }

      rethrow;
    }
  }

  @override
  Object? visitCall(Call call, [C? context]) {
    dynamic function = call.expression!.accept(this, context)!;

    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return Function.apply(function.call as Function, positional, named);
    }

    return callable<Object?>(call, context)(callback);
  }

  @override
  Object? visitCompare(Compare compare, [C? context]) {
    var left = compare.expression.accept(this, context);
    var result = true; // is needed?

    for (final operand in compare.operands) {
      final right = operand.expression.accept(this, context);

      switch (operand.operator) {
        case 'eq':
          result = result && tests.isEqual(left, right);
          break;
        case 'ne':
          result = result && tests.isNotEqual(left, right);
          break;
        case 'lt':
          result = result && tests.isLessThan(left, right);
          break;
        case 'le':
          result = result && tests.isLessThanOrEqual(left, right);
          break;
        case 'gt':
          result = result && tests.isGreaterThan(left, right);
          break;
        case 'ge':
          result = result && tests.isGreaterThanOrEqual(left, right);
          break;
        case 'in':
          result = result && tests.isIn(left, right);
          break;
        case 'notin':
          result = result && !tests.isIn(left, right);
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
  Object? visitCondition(Condition condition, [C? context]) {
    if (boolean(condition.test.accept(this, context))) {
      return condition.expression1.accept(this, context);
    }

    final expression = condition.expression2;

    if (expression != null) {
      return expression.accept(this, context);
    }

    return context!.environment.undefined();
  }

  @override
  Object? visitConstant(Constant<dynamic> constant, [C? context]) {
    return constant.value;
  }

  @override
  String visitData(Data data, [C? context]) {
    return data.data;
  }

  @override
  Map<Object?, Object?> visitDictLiteral(DictLiteral dict, [C? context]) {
    final result = <Object?, Object?>{};

    for (final pair in dict.pairs) {
      result[pair.key.accept(this, context)] = pair.value.accept(this, context);
    }

    return result;
  }

  @override
  Object? visitFilter(Filter filter, [C? context]) {
    Object? value;

    if (filter.expression != null) {
      value = filter.expression!.accept(this, context);
    }

    return callFilter(filter, value, context);
  }

  @override
  void visitFor(For forNode, [C? context]) {
    throw UnimplementedError();
  }

  @override
  void visitIf(If ifNode, [C? context]) {
    throw UnimplementedError();
  }

  @override
  Object? visitItem(Item item, [C? context]) {
    return context!.environment.getItem(item.expression.accept(this, context)!, item.key.accept(this, context));
  }

  @override
  MapEntry<Symbol, Object?> visitKeyword(Keyword keyword, [C? context]) {
    return MapEntry<Symbol, Object?>(Symbol(keyword.key), keyword.value.accept(this, context));
  }

  @override
  List<Object?> visitListLiteral(ListLiteral list, [C? context]) {
    final result = <Object?>[];

    for (final node in list.expressions) {
      result.add(node.accept(this, context));
    }

    return result;
  }

  @override
  Object? visitName(Name name, [C? context]) {
    switch (name.context) {
      case AssignContext.load:
        return context!.get(name.name);
      case AssignContext.store:
      case AssignContext.parameter:
        return name.name;
      default:
        throw UnimplementedError();
    }
  }

  @override
  Object? visitNamespaceReference(NamespaceReference reference, [C? context]) {
    return NSRef(reference.name, reference.attribute);
  }

  @override
  Object? visitOperand(Operand oprand, [C? context]) {
    return <dynamic>[oprand.operator, oprand.expression.accept(this, context)];
  }

  @override
  void visitOutput(Output output, [C? context]) {
    throw UnimplementedError();
  }

  @override
  MapEntry<Object?, Object?> visitPair(Pair pair, [C? context]) {
    return MapEntry<Object?, Object?>(pair.key.accept(this, context), pair.value.accept(this, context));
  }

  @override
  Indices visitSlice(Slice slice, [C? context]) {
    final sliceStart = slice.start?.accept(this, context) as int?;
    final sliceStop = slice.stop?.accept(this, context) as int?;
    final sliceStep = slice.step?.accept(this, context) as int?;
    return (int stopOrStart, [int? stop, int? step]) {
      if (sliceStep == null) {
        step = 1;
      } else if (sliceStep == 0) {
        throw StateError('slice step cannot be zero');
      } else {
        step = sliceStep;
      }

      int start;

      if (sliceStart == null) {
        start = step > 0 ? 0 : stopOrStart - 1;
      } else {
        start = sliceStart < 0 ? sliceStart + stopOrStart : sliceStart;
      }

      if (sliceStop == null) {
        stop = step > 0 ? stopOrStart : -1;
      } else {
        stop = sliceStop < 0 ? sliceStop + stopOrStart : sliceStop;
      }

      return range(start, stop, step);
    };
  }

  @override
  bool visitTest(Test test, [C? context]) {
    Object? value;

    if (test.expression != null) {
      value = test.expression!.accept(this, context);
    }

    return callTest(test, value, context);
  }

  @override
  List<Object?> visitTupleLiteral(TupleLiteral tuple, [C? context]) {
    switch (tuple.context) {
      case AssignContext.load:
        final result = <Object?>[];

        for (final node in tuple.expressions) {
          result.add(node.accept(this, context));
        }

        return result;
      case AssignContext.store:
        final result = <String>[];

        for (final node in tuple.expressions.cast<Name>()) {
          result.add(node.name);
        }

        return result;
      default:
        throw UnimplementedError();
    }
  }

  @override
  Object? visitUnary(Unary unaru, [C? context]) {
    final dynamic value = unaru.expression.accept(this, context);

    switch (unaru.operator) {
      case '+':
        // how i should implement this?
        return value;
      case '-':
        return -value;
      case 'not':
        return !boolean(value);
    }
  }

  @override
  void visitWith(With wiz, [C? context]) {
    throw UnimplementedError();
  }

  @protected
  static Symbol symbol(String keyword) {
    switch (keyword) {
      case 'default':
        return #d;
      default:
        return Symbol(keyword);
    }
  }
}
