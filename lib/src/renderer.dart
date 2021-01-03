import 'context.dart';
import 'enirvonment.dart';
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
    final iterable = forNode.iterable.accept(this, context);
    throw UnimplementedError();
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
}
