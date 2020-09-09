library template;

import 'ast.dart';
import 'environment.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Template {
  String render();
}

class RuntimeTemplate {
  final Environment environment;

  final Node node;

  factory RuntimeTemplate(
    String source, {
    String commentStart = '{#',
    String commentEnd = '#}',
    String expressionStart = '{{',
    String expressionEnd = '}}',
    String statementStart = '{%',
    String statementEnd = '%}',
    ItemGetter getItem = defaultGetItem,
    FieldGetter getField = defaultGetField,
    Finalizer finalize = defaultFinalizer,
  }) {
    final environment = Environment(
      commentStart: commentStart,
      commentEnd: commentEnd,
      expressionStart: expressionStart,
      expressionEnd: expressionEnd,
      statementStart: statementStart,
      statementEnd: statementEnd,
      getItem: getItem,
      getField: getField,
      finalize: finalize,
    );

    final node = Parser(environment).parse(source);
    return RuntimeTemplate.fromNode(node, environment);
  }

  RuntimeTemplate.fromNode(this.node, [this.environment = const Environment()]);

  @override
  String render({Map<String, Object> context}) {
    // TODO: profile
    // TODO: add to template?
    return MapRenderer(environment).visit(node, context);
  }

  @override
  String toString() {
    return 'Template $node';
  }
}
