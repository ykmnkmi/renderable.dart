import 'context.dart';
import 'enirvonment.dart';
import 'nodes.dart';
import 'utils.dart';
import 'visitor.dart';

class Renderer extends Visitor implements Context {
  Renderer(this.environment, this.sink, List<Node> nodes, [Map<String, Object?>? context])
      : contexts = <Map<String, Object?>>[environment.globals],
        stack = <Object?>[] {
    if (context != null) {
      contexts.add(context);
    }

    for (final node in nodes) {
      node.accept(this);

      if (stack.isNotEmpty) {
        sink.writeAll(stack.map<Object?>((value) => environment.finalize(value)));
        stack.clear();
      }
    }
  }

  @override
  final Environment environment;

  final StringSink sink;

  final List<Map<String, Object?>> contexts;

  final List<Object?> stack;

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
  void visitAttribute(Attribute node) {
    node.expression.accept(this);
    stack.add(environment.getAttribute(stack.removeLast(), node.attribute));
  }

  @override
  void visitBinary(Binary node) {
    throw 'implement visitBinary';
  }

  @override
  void visitCall(Call node) {
    node.expression.accept(this);
    final callable = unsafeCast<Function>(stack.removeLast());
    final arguments = <Object?>[];

    for (final argument in node.arguments) {
      argument.accept(this);
      arguments.add(stack.removeLast());
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      keywordArgument.accept(this);
      entry = unsafeCast(stack.removeLast());
      keywordArguments[entry.key] = entry.value;
    }

    stack.add(Function.apply(callable, arguments, keywordArguments));
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  void visitConcat(Concat node) {
    final buffer = StringBuffer();

    for (final expression in node.expressions) {
      expression.accept(this);
      buffer.write(stack.removeLast());
    }

    stack.add(buffer.toString());
  }

  @override
  void visitCondition(Condition node) {
    node.test.accept(this);

    if (boolean(stack.removeLast())) {
      node.expression1.accept(this);
    } else {
      final expression = node.expression2;

      if (expression != null) {
        expression.accept(this);
      } else {
        stack.add(null);
      }
    }
  }

  @override
  void visitConstant(Constant<Object?> node) {
    stack.add(node.value);
  }

  @override
  void visitData(Data node) {
    sink.write(node.data);
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    final dict = <Object?, Object?>{};
    stack.add(dict);

    MapEntry<Object?, Object?> entry;

    for (final pair in node.pairs) {
      pair.accept(this);
      entry = unsafeCast(stack.removeLast());
      dict[entry.key] = entry.value;
    }
  }

  @override
  void visitFilter(Filter node) {
    node.expression.accept(this);
    final arguments = <Object?>[stack.removeLast()];

    for (final argument in node.arguments) {
      argument.accept(this);
      arguments.add(stack.removeLast());
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      keywordArgument.accept(this);
      entry = unsafeCast(stack.removeLast());
      keywordArguments[entry.key] = entry.value;
    }

    stack.add(environment.callFilter(node.name, arguments, keywordArguments));
  }

  @override
  void visitIf(If node) {
    throw 'implement visitIf';
  }

  @override
  void visitItem(Item node) {
    node.key.accept(this);
    node.expression.accept(this);

    stack.add(environment.getItem(stack.removeLast(), stack.removeLast()));
  }

  @override
  void visitKeyword(Keyword node) {
    throw 'implement visitKeyword';
  }

  @override
  void visitListLiteral(ListLiteral node) {
    final list = <Object?>[];
    stack.add(list);

    for (final value in node.values) {
      value.accept(this);
      list.add(stack.removeLast());
    }
  }

  @override
  void visitName(Name node) {
    stack.add(get(node.name));
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
  void visitPair(Pair node) {
    node.key.accept(this);
    final key = stack.removeLast();
    node.value.accept(this);
    stack.add(MapEntry<Object?, Object?>(key, stack.removeLast()));
  }

  @override
  void visitSlice(Slice node) {
    throw 'implement visitSlice';
  }

  @override
  void visitTest(Test node) {
    node.expression.accept(this);
    final arguments = <Object?>[stack.removeLast()];

    for (final argument in node.arguments) {
      argument.accept(this);
      arguments.add(stack.removeLast());
    }

    final keywordArguments = <Symbol, Object?>{};
    MapEntry<Symbol, Object?> entry;

    for (final keywordArgument in node.keywordArguments) {
      keywordArgument.accept(this);
      entry = unsafeCast(stack.removeLast());
      keywordArguments[entry.key] = entry.value;
    }

    stack.add(environment.callTest(node.name, arguments, keywordArguments));
  }

  @override
  void visitTupleLiteral(TupleLiteral node) {
    final tuple = <Object?>[];
    stack.add(tuple);

    for (final value in node.values) {
      value.accept(this);
      tuple.add(stack.removeLast());
    }
  }

  @override
  void visitUnary(Unary node) {
    node.expression.accept(this);

    var value = stack.removeLast();

    switch (node.operator) {
      case '+':
        if (value is! num) {
          throw TypeError();
        }

        break;
      case '-':
        if (value is! num) {
          throw TypeError();
        }

        value = -value;
        break;
      case 'not':
        value = !boolean(value);
        break;
    }

    stack.add(value);
  }
}
