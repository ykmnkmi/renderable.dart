library visitor;

import 'package:meta/meta.dart';

import 'ast.dart';
import 'environment.dart';
import 'util.dart';

abstract class Visitor<C, R> {
  const Visitor();

  R visitText(Text text, [C context]);

  R visitVariable(Variable variable, [C context]);

  R visitInterpolation(Interpolation interpolation, [C context]);

  R visitIf(IfStatement ifStatement, [C context]);

  R visitAll(Iterable<Node> nodes, [C context]);

  R visit(Node node, [C context]) {
    return node.accept(this, context);
  }
}

@immutable
abstract class BaseRenderer<C> extends Visitor<C, String> {
  BaseRenderer(this.environment);

  final Environment environment;

  @override
  String visitText(Text text, [C context]) {
    return text.text;
  }

  @override
  String visitVariable(Variable variable, [C context]);

  @override
  String visitInterpolation(Interpolation interpolation, [C context]) {
    return visitAll(interpolation.nodes, context);
  }

  @override
  String visitIf(IfStatement ifStatement, [C context]) {
    final pairs = ifStatement.pairs;

    for (final pair in pairs.entries) {
      if (toBool(pair.key.accept(this, context))) {
        return pair.value.accept(this, context);
      }
    }

    final orElse = ifStatement.orElse;

    if (orElse != null) {
      return orElse.accept(this, context);
    }

    return '';
  }

  @override
  String visitAll(Iterable<Node> nodes, [C context]) {
    return nodes.map<String>((node) => node.accept<C, String>(this, context)).join();
  }

  @override
  String toString() {
    return 'Renderer<$C>()';
  }
}

class MapRenderer extends BaseRenderer<Map<String, Object>> {
  MapRenderer(Environment environment) : super(environment);

  @override
  String visitVariable(Variable variable, [Map<String, Object> context]) {
    final value = context[variable.name];
    return environment.finalize(value).toString();
  }
}
