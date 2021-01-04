import 'package:meta/meta.dart';

import 'context.dart';
import 'enirvonment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'utils.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink, [Map<String, dynamic>? data]) : super(environment, data);

  final StringSink sink;
}

class Renderer extends ExpressionResolver<RenderContext> {
  const Renderer(this.environment);

  final Environment environment;

  String render(List<Node> nodes, [Map<String, dynamic>? data]) {
    final buffer = StringBuffer();
    visitAll(nodes, RenderContext(environment, buffer, data));
    return buffer.toString();
  }

  @override
  void visitAll(List<Node> nodes, [RenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitData(Data data, [RenderContext? context]) {
    context!.sink.write(data.data);
  }

  @override
  void visitFor(For forNode, [RenderContext? context]) {
    final targets = forNode.target.accept(this, context) as List<String>;
    final iterable = forNode.iterable.accept(this, context);

    for (final value in iterable) {
      context!.apply<RenderContext>(unpack(targets, value), (context) {
        visitAll(forNode.body, context);
      });
    }
  }

  @override
  void visitIf(If ifNode, [RenderContext? context]) {
    if (boolean(ifNode.test.accept(this, context))) {
      visitAll(ifNode.body, context);
      return;
    }

    final ifNodes = ifNode.elseIf;

    if (ifNodes != null) {
      for (final ifNode in ifNodes) {
        if (boolean(ifNode.test.accept(this, context))) {
          visitAll(ifNode.body, context);
          return;
        }
      }
    }

    final nodes = ifNode.else_;

    if (nodes != null) {
      visitAll(nodes, context);
    }
  }

  @override
  void visitOutput(Output output, [RenderContext? context]) {
    for (final node in output.nodes) {
      if (node is Data) {
        node.accept(this, context);
      } else {
        context!.sink.write(context.environment.finalize(node.accept(this, context)));
      }
    }
  }

  @protected
  static Map<String, dynamic> unpack(List<String> targets, dynamic current) {
    if (targets.length == 1) {
      return <String, dynamic>{targets[0]: current};
    }

    final data = <String, dynamic>{};

    List<dynamic> list;

    if (current is List) {
      list = current;
    } else if (current is Iterable) {
      list = current.toList();
    } else if (current is String) {
      list = current.split('');
    } else {
      throw TypeError();
    }

    if (list.length < targets.length) {
      throw StateError('not enough values to unpack (expected ${targets.length}, got ${list.length})');
    }

    if (list.length > targets.length) {
      throw StateError('too many values to unpack (expected ${targets.length})');
    }

    for (var i = 0; i < targets.length; i++) {
      data[targets[i]] = list[i];
    }

    return data;
  }
}
