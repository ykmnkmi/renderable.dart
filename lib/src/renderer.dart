import 'context.dart';
import 'enirvonment.dart';
import 'filters.dart';
import 'nodes.dart';
import 'visitor.dart';

class Renderer extends Visitor implements Context {
  Renderer(this.environment, this.sink, List<Node> nodes, [Map<String, Object>? context])
      : contexts = <Map<String, Object>>[environment.globals],
        stack = [] {
    if (context != null) {
      contexts.add(context);
    }

    for (final node in nodes) {
      node.accept(this);

      if (stack.isNotEmpty) {
        sink.writeAll(stack.map<Object>((value) => environment.finalize(value)));
        stack.clear();
      }
    }
  }

  @override
  final Environment environment;

  final StringSink sink;

  final List<Map<String, Object>> contexts;

  final List<Object?> stack;

  @override
  Object operator [](String key) {
    return get(key);
  }

  @override
  void operator []=(String key, Object value) {
    set(key, value);
  }

  @override
  void apply(Map<String, Object> data, ContextCallback closure) {
    push(data);
    closure(this);
    pop();
  }

  @override
  Object get(String key) {
    Object? value;

    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        value = context[key];
        break;
      }
    }

    return environment.finalize(value);
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
  void push(Map<String, Object> context) {
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
  String toString() {
    return sink.toString();
  }

  @override
  void visitAttribute(Attribute node) {
    throw 'implement visitAttribute';
  }

  @override
  void visitBinary(Binary node) {
    throw 'implement visitBinary';
  }

  @override
  void visitCall(Call node) {
    throw 'implement visitCall';
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  void visitConcat(Concat node) {
    for (final expression in node.expressions) {
      expression.accept(this);
    }
  }

  @override
  void visitCondition(Condition node) {
    throw 'implement visitCondition';
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
    throw 'implement visitDictLiteral';
  }

  @override
  void visitFilter(Filter node) {
    throw 'implement visitFilter';
  }

  @override
  void visitIf(If node) {
    throw 'implement visitIf';
  }

  @override
  void visitItem(Item node) {
    throw 'implement visitItem';
  }

  @override
  void visitKeyword(Keyword node) {
    throw 'implement visitKeyword';
  }

  @override
  void visitListLiteral(ListLiteral node) {
    stack.add(<Object?>[]);

    for (final value in node.values) {
      value.accept(this);
      var last = stack.removeLast();
      (stack.last as List).add(last);
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
    throw 'implement visitPair';
  }

  @override
  void visitSlice(Slice node) {
    throw 'implement visitSlice';
  }

  @override
  void visitTest(Test node) {
    throw 'implement visitTest';
  }

  @override
  void visitTupleLiteral(TupleLiteral node) {
    throw 'implement visitTupleLiteral';
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
