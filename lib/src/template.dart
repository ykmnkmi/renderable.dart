library template;

import 'ast.dart';
import 'environment.dart';
import 'interface.dart';
import 'mirror.dart';
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
    FieldGetter getField = getField,
  }) {
    final environment = Environment();
    return Template<C>.fromNodes(Parser(environment).parse(source), environment);
  }

  Template.fromNodes(Iterable<Node> nodes, [Environment? environment])
      : environment = environment ?? const Environment(),
        nodes = nodes.toList(growable: false);

  @override
  String render([C? context]) {
    /* TODO: profile */
    return Renderer<C>(environment).visitAll(nodes, context).toString();
  }

  @override
  String toString() => 'Template $nodes';
}
