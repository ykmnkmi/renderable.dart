import 'dart:mirrors';

import 'package:renderable/renderable.dart';

typedef ItemGetter = dynamic Function(Map<String, dynamic> map, String key);

dynamic defaultGetItem(Map<String, dynamic> map, String key) {
  return map[key];
}

typedef FieldGetter = dynamic Function(dynamic object, String field);

T defaultGetField<T>(dynamic object, String field) {
  if (object == null) {
    return null;
  }

  return reflect(object).getField(Symbol(field)) as T;
}

typedef Finalizer = dynamic Function(dynamic value);

dynamic defaultFinalizer(dynamic value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return value.toString();
}

class RuntimeEnvironment extends Environment {
  const RuntimeEnvironment({
    String commentStart = '{#',
    String commentEnd = '#}',
    String expressionStart = '{{',
    String expressionEnd = '}}',
    String statementStart = '{%',
    String statementEnd = '%}',
    this.getItem = defaultGetItem,
    this.getField = defaultGetField,
    this.finalize = defaultFinalizer,
  })  : assert(commentStart != commentEnd),
        assert(expressionStart != expressionEnd),
        assert(statementStart != expressionEnd);

  factory RuntimeEnvironment.fromMap(Map<String, dynamic> config) {
    String commentStart, commentEnd;

    if (config.containsKey('comment_start')) {
      commentStart = config['comment_start'] as String;
    } else {
      commentStart = '{#';
    }

    if (config.containsKey('comment_end')) {
      commentEnd = config['comment_end'] as String;
    } else {
      commentEnd = '#}';
    }

    String expressionStart, expressionEnd;

    if (config.containsKey('expression_start')) {
      expressionStart = config['expression_start'] as String;
    } else {
      expressionStart = '{{';
    }

    if (config.containsKey('expression_end')) {
      expressionEnd = config['expression_end'] as String;
    } else {
      expressionEnd = '}}';
    }

    String statementStart, statementEnd;

    if (config.containsKey('statement_start')) {
      statementStart = config['statement_start'] as String;
    } else {
      statementStart = '{%';
    }

    if (config.containsKey('statement_end')) {
      statementEnd = config['statement_end'] as String;
    } else {
      statementEnd = '%}';
    }

    return RuntimeEnvironment(
      commentStart: commentStart,
      commentEnd: commentEnd,
      expressionStart: expressionStart,
      expressionEnd: expressionEnd,
      statementStart: statementStart,
      statementEnd: statementEnd,
    );
  }

  final ItemGetter getItem;

  final FieldGetter getField;

  final Finalizer finalize;

  @override
  RuntimeEnvironment change({
    String commentStart,
    String commentEnd,
    String expressionStart,
    String expressionEnd,
    String statementStart,
    String statementEnd,
    ItemGetter getItem,
    FieldGetter getField,
    Finalizer finalize,
  }) {
    return RuntimeEnvironment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      expressionStart: expressionStart ?? this.expressionStart,
      expressionEnd: expressionEnd ?? this.expressionEnd,
      statementStart: statementStart ?? this.statementStart,
      statementEnd: statementEnd ?? this.statementEnd,
      getField: getField ?? this.getField,
      finalize: finalize ?? this.finalize,
    );
  }
}

class RuntimeTemplate implements Template {
  final RuntimeEnvironment environment;

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
    final environment = RuntimeEnvironment(
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

  RuntimeTemplate.fromNode(this.node, [this.environment = const RuntimeEnvironment()]);

  @override
  String render({Map<String, dynamic> context}) {
    // TODO: profile
    // TODO: add to template?
    return MapRenderer(environment).visit(node, context);
  }

  @override
  String toString() {
    return 'Template $node';
  }
}

class MapRenderer extends BaseRenderer<RuntimeEnvironment, Map<String, dynamic>> {
  MapRenderer(RuntimeEnvironment environment) : super(environment);

  @override
  String visitVariable(Variable node, [Map<String, dynamic> context]) {
    final dynamic value = context[node.name];
    return environment.finalize(value).toString();
  }

  @override
  String visitIf(IfStatement node, [Map<String, dynamic> context]) {
    final pairs = node.pairs;

    for (final pair in pairs.entries) {
      if (defined(pair.key.accept(this, context))) {
        return pair.value.accept(this, context);
      }
    }

    final orElse = node.orElse;

    if (orElse != null) {
      return orElse.accept(this, context);
    }

    return '';
  }
}
