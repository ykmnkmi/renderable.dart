import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'context.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

const ExpressionResolver resolver = ExpressionResolver();

class ExpressionResolver<C extends Context> extends Visitor<C, dynamic> {
  @literal
  const ExpressionResolver();

  @protected // update
  T Function(T Function(List<dynamic>, Map<Symbol, dynamic>)) callable<T>(Callable callable, [C? context]) {
    final positional = <dynamic>[];

    if (callable.arguments != null) {
      for (final argument in callable.arguments!) {
        positional.add(argument.accept(this, context));
      }
    }

    final named = <Symbol, dynamic>{};

    if (callable.keywordArguments != null) {
      for (final keywordArgument in callable.keywordArguments!) {
        named[symbol(keywordArgument.key)] = keywordArgument.value.accept(this, context);
      }
    }
    if (callable.dArguments != null) {
      positional.addAll(callable.dArguments!.accept(this, context) as Iterable<dynamic>);
    }

    if (callable.dKeywordArguments != null) {
      named.addAll((callable.dKeywordArguments!.accept(this, context) as Map<dynamic, dynamic>)
          .cast<String, dynamic>()
          .map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(symbol(key), value)));
    }

    return (T Function(List<dynamic> positional, Map<Symbol, dynamic> named) callback) => callback(positional, named);
  }

  @protected
  dynamic callFilter(Filter filter, [dynamic value, C? context]) {
    dynamic callback(List<dynamic> positional, Map<Symbol, dynamic> named) {
      return context!.environment.callFilter(filter.name, value, positional: positional, named: named);
    }

    return callable(filter, context)(callback);
  }

  @protected
  bool callTest(Test test, [dynamic value, C? context]) {
    bool callback(List<dynamic> positional, Map<Symbol, dynamic> named) {
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
  dynamic visitCall(Call call, [C? context]) {
    ArgumentError.checkNotNull(call.expression);

    final function = call.expression!.accept(this, context);

    dynamic callback(List<dynamic> positional, Map<Symbol, dynamic> named) {
      if (function is Function) {
        return Function.apply(function, positional, named);
      }

      return context!.environment.callCallable(function, positional, named);
    }

    return callable(call, context)(callback);
  }

  @override
  dynamic visitCompare(Compare compare, [C? context]) {
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
    dynamic value;

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
  dynamic visitNamespaceReference(NamespaceReference reference, [C? context]) {
    return NSRef(reference.name, reference.attribute);
  }

  @override
  dynamic visitOperand(Operand oprand, [C? context]) {
    return <dynamic>[oprand.operator, oprand.expression.accept(this, context)];
  }

  @override
  void visitOutput(Output output, [C? context]) {
    throw UnimplementedError();
  }

  @override
  MapEntry<dynamic, dynamic> visitPair(Pair pair, [C? context]) {
    return MapEntry<dynamic, dynamic>(pair.key.accept(this, context), pair.value.accept(this, context));
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
    dynamic value;

    if (test.expression != null) {
      value = test.expression!.accept(this, context);
    }

    return callTest(test, value, context);
  }

  @override
  List<dynamic> visitTupleLiteral(TupleLiteral tuple, [C? context]) {
    switch (tuple.context) {
      case AssignContext.load:
        final result = <dynamic>[];

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
  dynamic visitUnary(Unary unaru, [C? context]) {
    final value = unaru.expression.accept(this, context);

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
        return #default_;
      default:
        return Symbol(keyword);
    }
  }
}
