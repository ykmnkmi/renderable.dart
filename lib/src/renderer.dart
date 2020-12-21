import 'dart:math' as math;

import 'context.dart';
import 'enirvonment.dart';
import 'filters.dart' as filters;
import 'nodes.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

class Renderer extends Visitor<dynamic> implements Context {
  Renderer(this.environment, this.sink, List<Node> nodes, [Map<String, dynamic>? context]) : contexts = <Map<String, dynamic>>[environment.globals] {
    if (context != null) {
      contexts.add(context);
    }

    visitAll(nodes);
  }

  @override
  final Environment environment;

  final StringSink sink;

  final List<Map<String, dynamic>> contexts;

  @override
  dynamic operator [](String key) {
    return get(key);
  }

  @override
  void operator []=(String key, Object value) {
    set(key, value);
  }

  @override
  void apply(Map<String, dynamic> data, ContextCallback closure) {
    push(data);
    closure(this);
    pop();
  }

  @override
  dynamic get(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return null;
  }

  @override
  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
  }

  @override
  void pop() {
    if (contexts.length > 2) {
      contexts.removeLast();
    }
  }

  @override
  void push(Map<String, dynamic> context) {
    contexts.add(context);
  }

  @override
  bool remove(String name) {
    for (final context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  @override
  void set(String key, Object value) {
    contexts.last[key] = value;
  }

  @override
  void visitAll(List<Node> nodes) {
    for (final node in nodes) {
      node.accept(this);
    }
  }

  @override
  dynamic visitAttribute(Attribute attribute) {
    return environment.getAttribute(attribute.expression.accept(this), attribute.attribute);
  }

  @override
  dynamic visitBinary(Binary binary) {
    final left = binary.left.accept(this);
    final right = binary.right.accept(this);

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
  dynamic visitCall(Call call) {
    final callable = unsafeCast<Function>(call.expression.accept(this));
    final arguments = <dynamic>[];

    for (final argument in call.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in call.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this);
    }

    var expression = call.dArguments;

    if (expression != null) {
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this)));
    }

    expression = call.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          unsafeCast<Map<String, dynamic>>(expression.accept(this)).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return Function.apply(callable, arguments, keywordArguments);
  }

  @override
  dynamic visitCompare(Compare compare) {
    var left = compare.expression.accept(this);
    var result = true;

    for (final operand in compare.operands) {
      if (!result) {
        return false;
      }

      final right = operand.expression.accept(this);

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
  dynamic visitConcat(Concat concat) {
    final buffer = StringBuffer();

    for (final expression in concat.expressions) {
      buffer.write(expression.accept(this));
    }

    return buffer.toString();
  }

  @override
  dynamic visitCondition(Condition condition) {
    if (boolean(condition.test.accept(this))) {
      return condition.expression1.accept(this);
    }

    final expression = condition.expression2;

    if (expression != null) {
      return expression.accept(this);
    }

    return null;
  }

  @override
  dynamic visitConstant(Constant<dynamic> constant) {
    return constant.value;
  }

  @override
  void visitData(Data data) {
    sink.write(data.data);
  }

  @override
  dynamic visitDictLiteral(DictLiteral dict) {
    final result = <dynamic, dynamic>{};

    for (final pair in dict.pairs) {
      result[pair.key.accept(this)] = pair.value.accept(this);
    }

    return result;
  }

  @override
  dynamic visitFilter(Filter filter) {
    final arguments = <dynamic>[filter.expression.accept(this)];

    for (final argument in filter.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in filter.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this);
    }

    var expression = filter.dArguments;

    if (expression != null) {
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this)));
    }

    expression = filter.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          unsafeCast<Map<String, dynamic>>(expression.accept(this)).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return environment.callFilter(filter.name, arguments, keywordArguments);
  }

  @override
  void visitIf(If node) {
    if (boolean(node.test.accept(this))) {
      visitAll(node.body);
      return;
    }

    if (node.elseIf.isNotEmpty) {
      for (final ifNode in node.elseIf) {
        if (boolean(ifNode.test.accept(this))) {
          visitAll(ifNode.body);
          return;
        }
      }
    }

    if (node.else_.isNotEmpty) {
      visitAll(node.else_);
    }
  }

  @override
  dynamic visitItem(Item item) {
    return environment.getItem(item.expression.accept(this), item.key.accept(this));
  }

  @override
  MapEntry<Symbol, dynamic> visitKeyword(Keyword keyword) {
    return MapEntry<Symbol, dynamic>(Symbol(keyword.key), keyword.value.accept(this));
  }

  @override
  dynamic visitListLiteral(ListLiteral list) {
    final result = <dynamic>[];

    for (final node in list.nodes) {
      result.add(node.accept(this));
    }

    return result;
  }

  @override
  dynamic visitName(Name name) {
    return get(name.name);
  }

  @override
  List<dynamic> visitOperand(Operand oprand) {
    return [oprand.operator, oprand.expression.accept(this)];
  }

  @override
  void visitOutput(Output output) {
    for (final node in output.nodes) {
      if (node is Data) {
        node.accept(this);
      } else {
        sink.write(environment.finalize(node.accept(this)));
      }
    }
  }

  @override
  dynamic visitPair(Pair pair) {
    return MapEntry<dynamic, dynamic>(pair.key.accept(this), pair.value.accept(this));
  }

  @override
  dynamic visitSlice(Slice slice_) {
    final value = slice_.expression.accept(this);
    final start = unsafeCast<int>(slice_.start.accept(this));

    var expression = slice_.stop;
    int? stop;

    if (expression != null) {
      stop = math.min(filters.count(value), unsafeCast<int>(expression.accept(this)));
    } else {
      stop = value.length;
    }

    expression = slice_.step;
    int? step;

    if (expression != null) {
      step = unsafeCast<int>(expression.accept(this));
    }

    if (value is String) {
      return sliceString(value, start, stop, step);
    }

    return slice(value, start, stop, step);
  }

  @override
  dynamic visitTest(Test test) {
    final arguments = <dynamic>[test.expression.accept(this)];

    for (final argument in test.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, dynamic>{};

    for (final keywordArgument in test.keywordArguments) {
      keywordArguments[Symbol(keywordArgument.key)] = keywordArgument.value.accept(this);
    }

    var expression = test.dArguments;

    if (expression != null) {
      arguments.addAll(unsafeCast<Iterable<dynamic>>(expression.accept(this)));
    }

    expression = test.dKeywordArguments;

    if (expression != null) {
      keywordArguments.addAll(
          unsafeCast<Map<String, dynamic>>(expression.accept(this)).map<Symbol, dynamic>((key, value) => MapEntry<Symbol, dynamic>(Symbol(key), value)));
    }

    return environment.callTest(test.name, arguments, keywordArguments);
  }

  @override
  dynamic visitTupleLiteral(TupleLiteral tuple) {
    final result = <dynamic>[];

    for (final node in tuple.nodes) {
      result.add(node.accept(this));
    }

    return result;
  }

  @override
  dynamic visitUnary(Unary unaru) {
    final value = unaru.expression.accept(this);

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
