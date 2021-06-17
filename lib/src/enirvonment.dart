import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show Random;

import 'package:renderable/jinja.dart';

import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'optimizer.dart';
import 'parser.dart';
import 'renderer.dart';
import 'runtime.dart';
import 'utils.dart';
import 'visitor.dart';

typedef Finalizer = Object? Function(Object? value);

typedef ContextFinalizer = Object? Function(Context context, Object? value);

typedef EnvironmentFinalizer = Object? Function(Environment environment, Object? value);

typedef FieldGetter = Object? Function(Object? object, String field);

typedef UndefinedFactory = Undefined Function({String? hint, Object? object, String? name});

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
    this.leftStripBlocks = defaults.lStripBlocks,
    this.trimBlocks = defaults.trimBlocks,
    this.newLine = defaults.newLine,
    this.keepTrailingNewLine = defaults.keepTrailingNewLine,
    this.optimized = true,
    this.undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    this.autoEscape = false,
    this.loader,
    this.autoReload = true,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    Map<String, Template>? templates,
    List<NodeVisitor>? modifiers,
    Random? random,
    this.getField = defaults.getField,
  })  : assert(finalize is Finalizer || finalize is ContextFinalizer || finalize is EnvironmentFinalizer),
        finalize = finalize is EnvironmentFinalizer
            ? ((context, value) => finalize(context.environment, value))
            : finalize is ContextFinalizer
                ? finalize
                : ((context, value) => finalize(value)),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        environmentFilters = HashSet<String>.of(defaults.environmentFilters),
        contextFilters = HashSet<String>.of(defaults.contextFilters),
        tests = HashMap<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
        modifiers = List<NodeVisitor>.of(defaults.modifiers),
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

    if (contextFilters != null) {
      this.contextFilters.addAll(contextFilters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
    }

    if (templates != null) {
      this.templates.addAll(templates);
    }

    if (modifiers != null) {
      this.modifiers.addAll(modifiers);
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

  final bool leftStripBlocks;

  final bool trimBlocks;

  final String newLine;

  final bool keepTrailingNewLine;

  final bool optimized;

  final UndefinedFactory undefined;

  final ContextFinalizer finalize;

  final bool autoEscape;

  final Loader? loader;

  final bool autoReload;

  final Map<String, Object?> globals;

  final Map<String, Function> filters;

  final Set<String> environmentFilters;

  final Set<String> contextFilters;

  final Map<String, Function> tests;

  final Map<String, Template> templates;

  final List<NodeVisitor> modifiers;

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
    bool? leftStripBlocks,
    bool? trimBlocks,
    String? newLine,
    bool? keepTrailingNewLine,
    bool? optimized,
    UndefinedFactory? undefined,
    Function? finalize,
    bool? autoEscape,
    Loader? loader,
    bool? autoReload,
    Map<String, dynamic>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    List<NodeVisitor>? modifiers,
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
      leftStripBlocks: leftStripBlocks ?? this.leftStripBlocks,
      trimBlocks: trimBlocks ?? this.trimBlocks,
      newLine: newLine ?? this.newLine,
      keepTrailingNewLine: keepTrailingNewLine ?? this.keepTrailingNewLine,
      optimized: optimized ?? this.optimized,
      undefined: undefined ?? this.undefined,
      finalize: finalize ?? this.finalize,
      autoEscape: autoEscape ?? this.autoEscape,
      loader: loader ?? this.loader,
      autoReload: autoReload ?? this.autoReload,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      environmentFilters: environmentFilters ?? this.environmentFilters,
      contextFilters: contextFilters ?? this.contextFilters,
      tests: tests ?? this.tests,
      modifiers: modifiers ?? this.modifiers,
      random: random ?? this.random,
      getField: getField ?? this.getField,
    );
  }

  Object? getItem(Object object, Object? key) {
    // TODO: update slices
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

  Object? callFilter(String name, Object? value,
      {List<Object?>? positional, Map<Symbol, Object?>? named, Context? context}) {
    Function filter;

    if (filters.containsKey(name)) {
      filter = filters[name]!;
    } else {
      throw TemplateRuntimeError('filter not found: $name');
    }

    if (contextFilters.contains(name)) {
      if (context == null) {
        throw TemplateRuntimeError('attempted to invoke context filter without context');
      }

      positional ??= <Object?>[];
      positional.insert(0, context);
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

  Template loadTemplate(String template) {
    if (loader == null) {
      throw UnsupportedError('no loader for this environment specified');
    }

    return templates[template] = loader!.load(this, template);
  }

  Template getTemplate(Object? template) {
    if (template is Undefined) {
      template.fail();
    }

    if (template is String) {
      if (autoReload && templates.containsKey(template)) {
        return templates[template] = loadTemplate(template);
      }

      return templates[template] ??= loadTemplate(template);
    }

    throw TypeError();
  }

  Template fromString(String source, {String? path}) {
    final template = Parser(this, path: path).parse(source);

    for (final modifier in modifiers) {
      for (final node in template.nodes) {
        modifier(node);
      }
    }

    if (optimized) {
      template.accept(const Optimizer(), Context(this));
    }

    return template;
  }
}

class Template extends Node {
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
    bool leftStripBlocks = defaults.lStripBlocks,
    String newLine = defaults.newLine,
    bool keepTrailingNewLine = defaults.keepTrailingNewLine,
    bool optimized = true,
    UndefinedFactory undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    bool autoEscape = false,
    Map<String, Object>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    List<NodeVisitor>? modifiers,
    Random? random,
    FieldGetter getField = defaults.getField,
  }) {
    Environment environment;

    if (parent != null) {
      // TODO: update copying
      environment = parent.copy(
        commentBegin: commentBegin,
        commentEnd: commentEnd,
        variableBegin: variableBegin,
        variableEnd: variableEnd,
        blockBegin: blockBegin,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        leftStripBlocks: leftStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        autoReload: false,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        contextFilters: contextFilters,
        tests: tests,
        modifiers: modifiers,
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
        leftStripBlocks: leftStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        autoReload: false,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        contextFilters: contextFilters,
        tests: tests,
        modifiers: modifiers,
        random: random,
        getField: getField,
      );
    }

    return environment.fromString(source, path: path);
  }

  Template.parsed(this.environment, this.nodes, {this.blocks = const <Block>[], this.path});

  final Environment environment;

  final List<Node> nodes;

  final List<Block> blocks;

  final String? path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitTemplate(this, context);
  }

  String render([Map<String, Object?>? data]) {
    final buffer = StringBuffer();
    final context = RenderContext(environment, buffer, data: data);
    accept(const StringSinkRenderer(), context);
    return buffer.toString();
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }
}
