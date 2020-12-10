import 'dart:math' as math;

import 'package:renderable/src/exceptions.dart';

import 'context.dart';
import 'enirvonment.dart';
import 'filters.dart' as filters;
import 'nodes.dart';
import 'utils.dart';
import 'visitor.dart';

class Renderer extends Visitor<Object?> implements Context {
  Renderer(this.environment, this.sink, List<Node> nodes, [Map<String, Object?>? context]) : contexts = <Map<String, Object?>>[environment.globals] {
    if (context != null) {
      contexts.add(context);
    }

    for (final node in nodes) {
      if (node is Expression) {
        sink.write(environment.finalize(node.accept(this)));
      } else {
        node.accept(this);
      }
    }
  }

  @override
  final Environment environment;

  final StringSink sink;

  final List<Map<String, Object?>> contexts;

  @override
  Object? operator [](String key) {
    return get(key);
  }

  @override
  void operator []=(String key, Object value) {
    set(key, value);
  }

  @override
  void apply(Map<String, Object?> data, ContextCallback closure) {
    push(data);
    closure(this);
    pop();
  }

  @override
  Object? get(String key) {
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
  void push(Map<String, Object?> context) {
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
  Object? visitAttribute(Attribute node) {
    return environment.getAttribute(node.expression.accept(this), node.attribute);
  }

  @override
  Object? visitBinary(Binary node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    try {
      switch (node.operator) {
        case '**':
          return math.pow(unsafeCast<num>(left), unsafeCast<num>(right));
        case '%':
          return unsafeCast<num>(left) % unsafeCast<num>(right);
        case '//':
          return unsafeCast<num>(left) ~/ unsafeCast<num>(right);
        case '/':
          return unsafeCast<num>(left) % unsafeCast<num>(right);
        case '*':
          return unsafeCast<dynamic>(left) * unsafeCast<dynamic>(right);
        default:
          throw TemplateRuntimeError();
      }
    } on TypeError {
      if (left is int && right is String) {
        return right * left;
      }

      rethrow;
    }
  }

  @override
  Object? visitCall(Call node) {
    final callable = unsafeCast<Function>(node.expression.accept(this));
    final arguments = <Object?>[];

    for (final argument in node.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      entry = unsafeCast<MapEntry<Symbol, Object?>>(keywordArgument.accept(this));
      keywordArguments[entry.key] = entry.value;
    }

    return Function.apply(callable, arguments, keywordArguments);
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  String visitConcat(Concat node) {
    final buffer = StringBuffer();

    for (final expression in node.expressions) {
      buffer.write(expression.accept(this));
    }

    return buffer.toString();
  }

  @override
  Object? visitCondition(Condition node) {
    if (boolean(node.test.accept(this))) {
      return node.expression1.accept(this);
    }

    final expression = node.expression2;

    if (expression != null) {
      return expression.accept(this);
    }

    return null;
  }

  @override
  Object? visitConstant(Constant<Object?> node) {
    return node.value;
  }

  @override
  void visitData(Data node) {
    sink.write(node.data);
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    final dict = <Object?, Object?>{};

    MapEntry<Object?, Object?> entry;

    for (final pair in node.pairs) {
      entry = unsafeCast<MapEntry<Object?, Object?>>(pair.accept(this));
      dict[entry.key] = entry.value;
    }
  }

  @override
  Object? visitFilter(Filter node) {
    final arguments = <Object?>[node.expression.accept(this)];

    for (final argument in node.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      entry = unsafeCast<MapEntry<Symbol, Object?>>(keywordArgument.accept(this));
      keywordArguments[entry.key] = entry.value;
    }

    return environment.callFilter(node.name, arguments, keywordArguments);
  }

  @override
  void visitIf(If node) {
    throw 'implement visitIf';
  }

  @override
  Object? visitItem(Item node) {
    return environment.getItem(node.expression.accept(this), node.key.accept(this));
  }

  @override
  void visitKeyword(Keyword node) {
    throw 'implement visitKeyword';
  }

  @override
  List<Object?> visitListLiteral(ListLiteral node) {
    final list = <Object?>[];

    for (final value in node.values) {
      list.add(value.accept(this));
    }

    return list;
  }

  @override
  Object? visitName(Name node) {
    return get(node.name);
  }

  @override
  void visitOperand(Operand node) {
    throw 'implement visitOperand';
  }

  @override
  void visitOutput(Output node) {
    throw 'implement visitOutput';
  }

  @override
  MapEntry<Object?, Object?> visitPair(Pair node) {
    return MapEntry<Object?, Object?>(node.key.accept(this), node.value.accept(this));
  }

  @override
  Object? visitSlice(Slice node) {
    final raw = node.expression.accept(this);
    final list = filters.list(raw);
    final start = unsafeCast<int>(node.start.accept(this));

    var expression = node.stop;
    int? stop;

    if (expression != null) {
      stop = math.min(list.length, unsafeCast<int>(expression.accept(this)));
    } else {
      stop = list.length;
    }

    expression = node.step;
    int? step;

    if (expression != null) {
      step = unsafeCast<int>(expression.accept(this));
    }

    final result = slice(list, start, stop, step);

    if (raw is String) {
      return result.join('');
    }

    return result;
  }

  @override
  Object? visitTest(Test node) {
    final arguments = <Object?>[node.expression.accept(this)];

    for (final argument in node.arguments) {
      arguments.add(argument.accept(this));
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      entry = unsafeCast<MapEntry<Symbol, Object?>>(keywordArgument.accept(this));
      keywordArguments[entry.key] = entry.value;
    }

    return environment.callTest(node.name, arguments, keywordArguments);
  }

  @override
  List<Object?> visitTupleLiteral(TupleLiteral node) {
    final tuple = <Object?>[];

    for (final value in node.values) {
      tuple.add(value.accept(this));
    }

    return tuple;
  }

  @override
  Object? visitUnary(Unary node) {
    final value = node.expression.accept(this);

    switch (node.operator) {
      case '+':
        return unsafeCast<num>(value);
      case '-':
        return -unsafeCast<num>(value);
      case 'not':
        return !boolean(value);
    }
  }
}
