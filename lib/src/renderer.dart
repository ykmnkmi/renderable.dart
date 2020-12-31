import 'context.dart';
import 'enirvonment.dart';
import 'nodes.dart';
import 'resolver.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink, [Map<String, dynamic>? data]) : super(environment, data);

  final StringSink sink;
}

class Renderer extends Resolver<RenderContext> {
  const Renderer(this.environment);

  final Environment environment;

  String render(List<Node> nodes, [Map<String, dynamic>? data]) {
    final buffer = StringBuffer();
    visitAll(nodes, RenderContext(environment, buffer, data));
    return buffer.toString();
  }

  @override
  void visitOutput(Output output, [RenderContext? context]) {
    for (final node in output.nodes) {
      if (node is Data) {
        context!.sink.write(node.accept(this, context));
      } else {
        context!.sink.write(context.environment.finalize(node.accept(this, context)));
      }
    }
  }
}
