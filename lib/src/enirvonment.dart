import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show Random;

import 'package:meta/meta.dart';

import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'optimizer.dart';
import 'parser.dart';
import 'renderable.dart';
import 'renderer.dart';
import 'runtime.dart';
import 'utils.dart';
import 'visitor.dart';

typedef Finalizer = Object? Function(Object? value);

typedef ContextFinalizer = Object? Function(Context context, Object? value);

typedef EnvironmentFinalizer = Object? Function(Environment environment, Object? value);

typedef Caller = Object? Function(Object object, List<Object?> positional, [Map<Symbol, Object?> named]);

typedef FieldGetter = Object? Function(Object? object, String field);

typedef UndefinedFactory = Undefined Function({String? hint, Object? object, String? name});

@immutable
class Environment {
  Environment({
    this.commentBegin = defaults.commentBegin,
    this.commentEnd = defaults.commentEnd,
    this.variableBegin = defaults.variableBegin,
    this.variableEnd = defaults.variableEnd,
    this.blockBegin = defaults.blockBegin,
    this.blockEnd = defaults.blockEnd,
    this.lineCommentPrefix = defaults.lineCommentPrefix,
    this.lineStatementPrefix = defaults.lineStatementPrefix,
    this.lStripBlocks = defaults.lStripBlocks,
    this.trimBlocks = defaults.trimBlocks,
    this.newLine = defaults.newLine,
    this.keepTrailingNewLine = defaults.keepTrailingNewLine,
    this.optimized = true,
    this.undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    this.autoEscape = false,
    this.loader,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    Map<String, Template>? templates,
    Random? random,
    this.getField = defaults.getField,
  })  : assert(finalize is Finalizer || finalize is ContextFinalizer || finalize is EnvironmentFinalizer),
        finalize = finalize is EnvironmentFinalizer
            ? ((context, value) => finalize(context.environment, value))
            : finalize is ContextFinalizer
                ? finalize
                : ((context, value) => finalize(value)),
        globals = Map<String, Object?>.of(defaults.globals),
        filters = Map<String, Function>.of(defaults.filters),
        environmentFilters = HashSet<String>.of(defaults.environmentFilters),
        contextFilters = HashSet<String>.of(defaults.contextFilters),
        tests = Map<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
        random = random ?? Random() {
    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (environmentFilters != null) {
      this.environmentFilters.addAll(environmentFilters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
    }

    if (templates != null) {
      this.templates.addAll(templates);
    }
  }

  final String commentBegin;

  final String commentEnd;

  final String variableBegin;

  final String variableEnd;

  final String blockBegin;

  final String blockEnd;

  final String? lineCommentPrefix;

  final String? lineStatementPrefix;

  final bool lStripBlocks;

  final bool trimBlocks;

  final String newLine;

  final bool keepTrailingNewLine;

  final bool optimized;

  final UndefinedFactory undefined;

  final ContextFinalizer finalize;

  final bool autoEscape;

  final Loader? loader;

  final Map<String, Object?> globals;

  final Map<String, Function> filters;

  final Set<String> environmentFilters;

  final Set<String> contextFilters;

  final Map<String, Function> tests;

  final Map<String, Template> templates;

  final Random random;

  final FieldGetter getField;

  Environment copy({
    String? commentBegin,
    String? commentEnd,
    String? variableBegin,
    String? variableEnd,
    String? blockBegin,
    String? blockEnd,
    String? lineCommentPrefix,
    String? lineStatementPrefix,
    bool? lStripBlocks,
    bool? trimBlocks,
    String? newLine,
    bool? keepTrailingNewLine,
    bool? optimized,
    UndefinedFactory? undefined,
    Function? finalize,
    bool? autoEscape,
    Loader? loader,
    Map<String, dynamic>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    Random? random,
    FieldGetter? getField,
  }) {
    return Environment(
      commentBegin: commentBegin ?? this.commentBegin,
      commentEnd: commentEnd ?? this.commentEnd,
      variableBegin: variableBegin ?? this.variableBegin,
      variableEnd: variableEnd ?? this.variableEnd,
      blockBegin: blockBegin ?? this.blockBegin,
      blockEnd: blockEnd ?? this.blockEnd,
      lineCommentPrefix: lineCommentPrefix ?? this.lineCommentPrefix,
      lineStatementPrefix: lineStatementPrefix ?? this.lineStatementPrefix,
      lStripBlocks: lStripBlocks ?? this.lStripBlocks,
      trimBlocks: trimBlocks ?? this.trimBlocks,
      newLine: newLine ?? this.newLine,
      keepTrailingNewLine: keepTrailingNewLine ?? this.keepTrailingNewLine,
      optimized: optimized ?? this.optimized,
      undefined: undefined ?? this.undefined,
      finalize: finalize ?? this.finalize,
      autoEscape: autoEscape ?? this.autoEscape,
      loader: loader ?? this.loader,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      environmentFilters: environmentFilters ?? this.environmentFilters,
      contextFilters: contextFilters ?? this.contextFilters,
      tests: tests ?? this.tests,
      random: random ?? this.random,
      getField: getField ?? this.getField,
    );
  }

  Object? getItem(Object object, Object? key) {
    if (key is Indices) {
      if (object is String) {
        return sliceString(object, key);
      }

      if (object is List<Object?>) {
        return slice(object, key);
      }

      if (object is Iterable<Object?>) {
        return slice(object.toList(), key);
      }
    }

    if (key is int && key < 0) {
      key = key + ((object as dynamic).length as int);
    }

    try {
      return (object as dynamic)[key];
    } on NoSuchMethodError {
      if (key is String) {
        try {
          return getField(object, key);
        } on NoSuchMethodError {
          // do nothing.
        }
      }

      return undefined(object: object, name: '$key');
    }
  }

  Object? getAttribute(Object? object, String field) {
    try {
      return getField(object, field);
    } on NoSuchMethodError {
      try {
        return (object as dynamic)[field];
      } on NoSuchMethodError {
        return undefined(object: object, name: field);
      }
    }
  }

  Object? callFilter(String name, Object? value, {List<Object?>? positional, Map<Symbol, Object?>? named, Context? context}) {
    Function filter;

    if (filters.containsKey(name)) {
      filter = filters[name]!;
    } else {
      throw TemplateRuntimeError('filter not found: $name');
    }

    if (contextFilters.contains(name)) {
      positional ??= <Object?>[];
      positional.insert(0, /* TODO: error message */ context!);
      positional.insert(1, value);
    } else if (environmentFilters.contains(name)) {
      positional ??= <Object?>[];
      positional.insert(0, this);
      positional.insert(1, value);
    } else {
      positional ??= <Object?>[];
      positional.insert(0, value);
    }

    return Function.apply(filter, positional, named);
  }

  bool callTest(String name, Object? value, {List<Object?>? positional, Map<Symbol, Object?>? named}) {
    Function test;

    if (tests.containsKey(name)) {
      test = tests[name]!;
    } else {
      throw TemplateRuntimeError('test not found: $name');
    }

    positional ??= <Object?>[];
    positional.insert(0, value);

    return Function.apply(test, positional, named) as bool;
  }

  List<Node> parse(String source, {String? path}) {
    return Parser(this).parse(source, path: path);
  }

  @protected
  Template loadTemplate(String name) {
    if (loader == null) {
      throw UnsupportedError('no loader for this environment specified');
    }

    if (templates.containsKey(name)) {
      return templates[name]!;
    }

    return templates[name] = loader!.load(this, name);
  }

  Template getTemplate(Object? name) {
    if (name is Template) {
      return name;
    }

    return loadTemplate(name as String);
  }

  Template selectTemplate(List<Object?> names) {
    if (names.isEmpty) {
      throw TemplateNotFound(message: 'tried to select from an empty list of templates');
    }

    for (final name in names) {
      if (name is Template) {
        return name;
      }

      try {
        return loadTemplate(name as String);
      } on TemplateNotFound {
        continue;
      }
    }

    throw TemplatesNotFound(names: names);
  }

  Template fromString(String source, {String? path}) {
    final nodes = parse(source, path: path);
    final template = Template.parsed(this, nodes, path: path);

    if (optimized) {
      template.accept(const Optimizer(), Context(this));
    }

    return template;
  }
}

class Template extends Node implements Renderable {
  factory Template(
    String source, {
    String? path,
    Environment? parent,
    String blockBegin = defaults.blockBegin,
    String blockEnd = defaults.blockEnd,
    String variableBegin = defaults.variableBegin,
    String variableEnd = defaults.variableEnd,
    String commentBegin = defaults.commentBegin,
    String commentEnd = defaults.commentEnd,
    String? lineCommentPrefix = defaults.lineCommentPrefix,
    String? lineStatementPrefix = defaults.lineStatementPrefix,
    bool trimBlocks = defaults.trimBlocks,
    bool lStripBlocks = defaults.lStripBlocks,
    String newLine = defaults.newLine,
    bool keepTrailingNewLine = defaults.keepTrailingNewLine,
    bool optimized = true,
    UndefinedFactory undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    bool autoEscape = false,
    Map<String, Object>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Map<String, Function>? tests,
    Random? random,
    FieldGetter getField = defaults.getField,
  }) {
    Environment environment;

    if (parent != null) {
      environment = parent.copy(
        commentBegin: commentBegin,
        commentEnd: commentEnd,
        variableBegin: variableBegin,
        variableEnd: variableEnd,
        blockBegin: blockBegin,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        lStripBlocks: lStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        tests: tests,
        random: random,
        getField: getField,
      );
    } else {
      environment = Environment(
        commentBegin: commentBegin,
        commentEnd: commentEnd,
        variableBegin: variableBegin,
        variableEnd: variableEnd,
        blockBegin: blockBegin,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        lStripBlocks: lStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        tests: tests,
        random: random,
        getField: getField,
      );
    }

    return environment.fromString(source, path: path);
  }

  Template.parsed(
    this.environment,
    List<Node> nodes, {
    String? path,
    List<NodeVisitor> visitors = const <NodeVisitor>[Namespace.prepare],
  })  : nodes = List<Node>.of(nodes),
        path = path {
    for (final visitor in visitors) {
      for (final node in nodes) {
        visitor(node);
      }
    }

    if (path != null) {
      environment.templates[path] = this;
    }
  }

  final Environment environment;

  final List<Node> nodes;

  final String? path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitTemplate(this, context);
  }

  @override
  Iterable<String> generate([Map<String, Object?>? data]) {
    throw UnimplementedError();
  }

  @override
  String render([Map<String, Object?>? data]) {
    final buffer = StringBuffer();
    final context = StringBufferRenderContext(environment, buffer: buffer, data: data);
    accept(const Renderer(), context);
    return buffer.toString();
  }

  @override
  Stream<String> stream([Map<String, Object?>? data]) {
    throw UnimplementedError();
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }
}
