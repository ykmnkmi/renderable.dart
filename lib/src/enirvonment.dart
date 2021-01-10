import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show Random;

import 'configuration.dart';
import 'context.dart';
import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'nodes.dart';
import 'parser.dart';
import 'renderable.dart';
import 'renderer.dart';
import 'utils.dart';

typedef FieldGetter = dynamic Function(dynamic object, String field);

typedef Caller = dynamic Function(dynamic object, List<dynamic> positional, [Map<Symbol, dynamic> named]);

class Environment extends Configuration {
  Environment(
      {String blockBegin = defaults.blockBegin,
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
      bool optimized = true,
      Finalizer finalize = defaults.finalize,
      bool autoEscape = false,
      Map<String, dynamic>? globals,
      Map<String, Function>? filters,
      Set<String>? contextFilters,
      Set<String>? environmentFilters,
      Map<String, Function>? tests,
      Map<String, Template>? templates,
      Random? random,
      this.getField = defaults.getField,
      this.callCallable = defaults.callCallable})
      : templates = HashMap<String, Template>(),
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
            optimized: optimized,
            finalize: finalize,
            autoEscape: autoEscape,
            globals: HashMap<String, dynamic>.of(defaults.globals),
            filters: HashMap<String, Function>.of(defaults.filters),
            contextFilters: HashSet<String>.of(defaults.contextFilters),
            environmentFilters: HashSet<String>.of(defaults.environmentFilters),
            tests: HashMap<String, Function>.of(defaults.tests)) {
    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (contextFilters != null) {
      this.contextFilters.addAll(contextFilters);
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

  final FieldGetter getField;

  final Caller callCallable;

  final Map<String, Template> templates;

  @override
  Environment copy(
      {String? commentBegin,
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
      Finalizer? finalize,
      bool? autoEscape,
      Random? random,
      Map<String, dynamic>? globals,
      Map<String, Function>? filters,
      Set<String>? contextFilters,
      Set<String>? environmentFilters,
      Map<String, Function>? tests,
      FieldGetter? getField,
      Caller? callCallable}) {
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
      finalize: finalize ?? this.finalize,
      autoEscape: autoEscape ?? this.autoEscape,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      contextFilters: contextFilters ?? this.contextFilters,
      environmentFilters: environmentFilters ?? this.environmentFilters,
      tests: tests ?? this.tests,
      random: random ?? this.random,
      getField: getField ?? this.getField,
      callCallable: callCallable ?? this.callCallable,
    );
  }

  dynamic getAttribute(dynamic object, String field) {
    try {
      return getField(object, field);
    } on NoSuchMethodError {
      try {
        return object[field];
      } on NoSuchMethodError {
        return null;
      }
    }
  }

  dynamic getItem(dynamic object, dynamic key) {
    if (key is Indices) {
      if (object is List) {
        return slice(object, key);
      }

      if (object is String) {
        return sliceString(object, key);
      }

      if (object is Iterable) {
        return slice(object.toList(), key);
      }
    }

    return object[key];
  }

  Template fromString(String source, {String? path}) {
    final template = Template.parsed(this, Parser(this).parse(source, path: path), path);

    if (path != null) {
      templates[path] = template;
    }

    return template;
  }

  dynamic callFilter(String name, dynamic value, {List<dynamic> positional = const [], Map<Symbol, dynamic> named = const {}}) {
    Function filter;

    if (filters.containsKey(name)) {
      filter = filters[name]!;
    } else {
      throw TemplateRuntimeError('filter not found: $name');
    }

    if (environmentFilters.contains(name)) {
      positional.insert(0, this);
      positional.insert(1, value);
    } else {
      positional.insert(0, value);
    }

    return Function.apply(filter, positional, named);
  }

  bool callTest(String name, dynamic value, {List<dynamic> positional = const [], Map<Symbol, dynamic> named = const {}}) {
    Function test;

    if (tests.containsKey(name)) {
      test = tests[name]!;
    } else {
      throw TemplateRuntimeError('test not found: $name');
    }

    positional.insert(0, value);

    return Function.apply(test, positional, named) as bool;
  }
}

class Template implements Renderable {
  factory Template(String source,
      {String? path,
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
      Finalizer finalize = defaults.finalize,
      bool autoEscape = false,
      Map<String, Object>? globals,
      Map<String, Function>? filters,
      Map<String, Function>? tests,
      Random? random,
      FieldGetter getField = defaults.getField}) {
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
          finalize: finalize,
          autoEscape: autoEscape,
          globals: globals,
          filters: filters,
          tests: tests,
          random: random,
          getField: getField);
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
          globals: globals,
          filters: filters,
          tests: tests,
          random: random,
          getField: getField);
    }

    final nodes = Parser(environment).parse(source, path: path);
    return Template.parsed(environment, nodes, path);
  }

  Template.parsed(this.environment, List<Node> nodes, [String? path])
      : renderer = Renderer(environment),
        nodes = List<Node>.of(nodes),
        path = path {
    nodes.forEach(prepare);

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

void prepare(Node node) {
  if (node is Call) {
    var expression = node.expression;

    if (expression is Name && expression.name == 'namespace') {
      final arguments = node.arguments == null ? <Expression>[] : node.arguments!.toList();
      node.arguments = null;

      if (node.keywordArguments != null && node.keywordArguments!.isNotEmpty) {
        final dict = DictLiteral(node.keywordArguments!.map<Pair>((keyword) => Pair(Constant<String>(keyword.key), keyword.value)).toList());
        node.keywordArguments = null;
        arguments.add(dict);
      }

      expression = node.dArguments;

      if (expression != null) {
        arguments.add(expression);
        node.dArguments = null;
      }

      expression = node.dKeywordArguments;

      if (expression != null) {
        arguments.add(expression);
        node.dKeywordArguments = null;
      }

      if (arguments.isNotEmpty) {
        node.arguments = <Expression>[ListLiteral(arguments)];
      }

      return;
    }
  }

  node.visitChildNodes(prepare);
}
