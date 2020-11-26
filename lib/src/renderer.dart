import 'context.dart';
import 'enirvonment.dart';
import 'filters.dart';
import 'nodes.dart';
import 'visitor.dart';

class Renderer implements Context, Visitor {
  Renderer(this.environment, List<Node> nodes, [Map<String, Object> context])
      : buffer = StringBuffer(),
        contexts = <Map<String, Object>>[environment.globals] {
    if (context != null) {
      contexts.add(context);
    }

    for (final node in nodes) {
      node.accept(this);
    }
  }

  @override
  final Environment environment;

  final StringBuffer buffer;

  final List<Map<String, Object>> contexts;

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
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return environment.finalize(context[key]);
      }
    }

    return environment.finalize(null);
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
    return buffer.toString();
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
  void visitConstant(Constant<Object> node) {
    buffer.write(represent(node.value));
  }

  @override
  void visitData(Data node) {
    buffer.write(node.data);
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
    var notFirst = false;
    buffer.write('[');

    for (final value in node.values) {
      if (notFirst) {
        buffer.write(', ');
      } else {
        notFirst = true;
      }

      value.accept(this);
    }

    buffer.write(']');
  }

  @override
  void visitName(Name node) {
    buffer.write(environment.finalize(get(node.name)));
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
    throw 'implement visitUnary';
  }
}
