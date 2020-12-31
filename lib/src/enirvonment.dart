import 'dart:collection' show HashMap, HashSet;

import 'configuration.dart';
import 'context.dart';
import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'nodes.dart';
import 'parser.dart';
import 'renderable.dart';
import 'renderer.dart';

typedef Finalizer = dynamic Function([dynamic value]);

typedef AttributeGetter = dynamic Function(dynamic object, String field);

typedef ItemGetter = dynamic Function(dynamic object, dynamic key);

class Environment extends Configuration {
  Environment({
    String blockBegin = defaults.blockBegin,
    String blockEnd = defaults.blockEnd,
    String variableBegin = defaults.variableBegin,
    String variableEnd = defaults.variableEnd,
    String commentBegin = defaults.commentBegin,
    String commentEnd = defaults.commentEnd,
    String lineCommentPrefix = defaults.lineCommentPrefix,
    String lineStatementPrefix = defaults.lineStatementPrefix,
    bool trimBlocks = defaults.trimBlocks,
    bool lStripBlocks = defaults.lStripBlocks,
    String newLine = defaults.newLine,
    bool keepTrailingNewLine = defaults.keepTrailingNewLine,
    this.finalize = defaults.finalizer,
    this.autoEscape = false,
    this.getAttribute = defaults.getAttribute,
    this.getItem = defaults.getItem,
    Map<String, dynamic>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
    Map<String, Template>? templates,
  })  : globals = HashMap<String, dynamic>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        contextFilters = HashSet<String>.of(defaults.contextFilters),
        environmentFilters = HashSet<String>.of(defaults.environmentFilters),
        tests = HashMap<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
        super(
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
        ) {
    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
    }

    if (templates != null) {
      this.templates.addAll(templates);
    }
  }

  final Map<String, dynamic> globals;

  final Map<String, Function> filters;

  final Set<String> contextFilters;

  final Set<String> environmentFilters;

  final Map<String, Function> tests;

  final Finalizer finalize;

  final bool autoEscape;

  final AttributeGetter getAttribute;

  final ItemGetter getItem;

  final Map<String, Template> templates;

  @override
  Environment change({
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
    Finalizer? finalize,
    bool? autoEscape,
    AttributeGetter? getAttribute,
    ItemGetter? getItem,
    Map<String, dynamic>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
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
      finalize: finalize ?? this.finalize,
      autoEscape: autoEscape ?? this.autoEscape,
      getAttribute: getAttribute ?? this.getAttribute,
      getItem: getItem ?? this.getItem,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      tests: tests ?? this.tests,
    );
  }

  Template fromString(String source, {String? path}) {
    final template = Template.parsed(this, Parser(this).parse(source, path: path), path);

    if (path != null) {
      templates[path] = template;
    }

    return template;
  }

  dynamic callFilter(String name, dynamic value,
      {List<dynamic> arguments = const <dynamic>[], Map<Symbol, dynamic> keywordArguments = const <Symbol, dynamic>{}, Context? context}) {
    Function filter;

    if (filters.containsKey(name)) {
      filter = filters[name]!;
    } else {
      throw TemplateRuntimeError('filter not found: $name');
    }

    arguments.insert(0, value);

    if (contextFilters.contains(name)) {
      if (context == null) {
        throw TemplateRuntimeError('context is null');
      }

      arguments.insert(0, context);
    }

    if (environmentFilters.contains(name)) {
      arguments.insert(0, this);
    }

    return Function.apply(filter, arguments, keywordArguments);
  }

  bool callTest(String name, dynamic value, {List<dynamic> arguments = const <dynamic>[], Map<Symbol, dynamic> keywordArguments = const <Symbol, dynamic>{}}) {
    Function test;

    if (tests.containsKey(name)) {
      test = tests[name]!;
    } else {
      throw TemplateRuntimeError('test not found: $name');
    }

    arguments.insert(0, value);

    return Function.apply(test, arguments, keywordArguments) as bool;
  }
}

class Template extends Renderable {
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
    String lineCommentPrefix = defaults.lineCommentPrefix,
    String lineStatementPrefix = defaults.lineStatementPrefix,
    bool trimBlocks = defaults.trimBlocks,
    bool lStripBlocks = defaults.lStripBlocks,
    String newLine = defaults.newLine,
    bool keepTrailingNewLine = defaults.keepTrailingNewLine,
    Finalizer finalize = defaults.finalizer,
    bool autoEscape = false,
    AttributeGetter getAttribute = defaults.getAttribute,
    ItemGetter getItem = defaults.getItem,
    Map<String, Object>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
  }) {
    Environment environment;

    if (parent != null) {
      environment = parent.change(
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
        finalize: finalize,
        autoEscape: autoEscape,
        getAttribute: getAttribute,
        getItem: getItem,
        globals: globals,
        filters: filters,
        tests: tests,
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
        finalize: finalize,
        autoEscape: autoEscape,
        getAttribute: getAttribute,
        getItem: getItem,
        globals: globals,
        filters: filters,
        tests: tests,
      );
    }

    final nodes = Parser(environment).parse(source, path: path);
    return Template.parsed(environment, nodes, path);
  }

  Template.parsed(this.environment, this.nodes, [String? path])
      : renderer = Renderer(environment),
        path = path {
    if (path != null) {
      environment.templates[path] = this;
    }
  }

  final Environment environment;

  final Renderer renderer;

  final List<Node> nodes;

  final String? path;

  @override
  String render([Map<String, dynamic>? data]) {
    return renderer.render(nodes, data);
  }
}
