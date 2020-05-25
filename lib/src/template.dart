library template;

import 'ast.dart';
import 'environment.dart';
import 'interface.dart';
import 'default.dart' as d;
import 'parser.dart';
import 'visitor.dart';

class Template<C> implements Renderable<C> {
  final List<Node> nodes;

  final Environment environment;

  factory Template(
    String source, {
    String commentStart = '{#',
    String commentEnd = '#}',
    String expressionStart = '{{',
    String expressionEnd = '}}',
    String statementStart = '{%',
    String statementEnd = '%}',
    FieldGetter getField = d.getField,
    Finalizer finalize = d.finalizer,
  }) {
    final environment = Environment(
      commentStart: commentStart,
      commentEnd: commentEnd,
      expressionStart: expressionStart,
      expressionEnd: expressionEnd,
      statementStart: statementStart,
      statementEnd: statementEnd,
      getField: getField,
      finalize: finalize,
    );

    final nodes = Parser(environment).parse(source);
    return Template<C>.fromNodes(nodes, environment);
  }

  Template.fromNodes(Iterable<Node> nodes, [Environment environment])
      : environment = environment ?? const Environment(),
        nodes = nodes.toList(growable: false);

  @override
  String render([C context]) {
    /* TODO: profile */
    return Renderer<C>(environment).visitAll(nodes, context).toString();
  }

  @override
  String toString() {
    return 'Template $nodes';
  }
}
