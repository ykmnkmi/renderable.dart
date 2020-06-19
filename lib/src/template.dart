library template;

import 'ast.dart';
import 'environment.dart';
import 'interface.dart';
import 'default.dart' as d;
import 'parser.dart';
import 'visitor.dart';

class Template<C> implements Renderable<C> {
  final Node node;

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

    final node = Parser(environment).parse(source);
    return Template<C>.fromNode(node, environment);
  }

  Template.fromNode(this.node, [Environment environment]) : environment = environment ?? const Environment();

  @override
  String render([C context]) {
    /* TODO: profile render */
    return Renderer<C>(environment).visit(node, context);
  }

  @override
  String toString() {
    return 'Template $node';
  }
}
