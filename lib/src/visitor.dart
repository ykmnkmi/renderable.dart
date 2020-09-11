library visitor;

import 'ast.dart';
import 'environment.dart';

abstract class Visitor<C, R> {
  const Visitor();

  R visitText(Text node, [C context]);

  R visitVariable(Variable node, [C context]);

  R visitAll(Iterable<Node> nodes, [C context]);

  R visitInterpolation(Interpolation node, [C context]);

  R visitIf(IfStatement node, [C context]);

  R visit(Node node, [C context]) {
    return node.accept(this, context);
  }
}

abstract class BaseRenderer<E extends Environment, C> extends Visitor<C, String> {
  BaseRenderer(this.environment);

  final E environment;

  @override
  String visitText(Text node, [C context]) {
    return node.text;
  }

  @override
  String visitVariable(Variable node, [C context]);

  @override
  String visitAll(Iterable<Node> nodes, [C context]) {
    return nodes.map<String>((node) => node.accept<C, String>(this, context)).join();
  }

  @override
  String visitInterpolation(Interpolation node, [C context]) {
    return visitAll(node.children, context);
  }

  @override
  String visitIf(IfStatement node, [C context]);

  @override
  String toString() {
    return 'Renderer<$C>()';
  }
}
