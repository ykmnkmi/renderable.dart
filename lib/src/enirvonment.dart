import 'configuration.dart';
import 'defaults.dart' as defaults;
import 'nodes.dart';
import 'parser.dart';
import 'renderable.dart';
import 'renderer.dart';

typedef Finalizer = Object? Function([Object? value]);

typedef ItemGetter = Object? Function(Object? object, Object? key);

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
    this.getItem = defaults.itemGetter,
    Map<String, Object>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
    Map<String, Template>? templates,
  })  : globals = Map<String, Object>.from(defaults.globals),
        filters = Map<String, Function>.from(defaults.filters),
        tests = Map<String, Function>.from(defaults.tests),
        templates = <String, Template>{},
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

  final Map<String, Object> globals;

  final Map<String, Function> filters;

  final Map<String, Function> tests;

  final Finalizer finalize;

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
    ItemGetter? getItem,
    Map<String, Object>? globals,
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
    ItemGetter getItem = defaults.itemGetter,
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
        getItem: getItem,
        globals: globals,
        filters: filters,
        tests: tests,
      );
    }

    final nodes = Parser(environment).parse(source, path: path);
    return Template.parsed(environment, nodes, path);
  }

  Template.parsed(this.environment, this.nodes, [String? path]) : path = path {
    if (path != null) {
      environment.templates[path] = this;
    }
  }

  final Environment environment;

  final List<Node> nodes;

  final String? path;

  @override
  String render([Map<String, Object?>? context]) {
    // TODO: update
    final buffer = StringBuffer();
    Renderer(environment, buffer, nodes, context);
    return buffer.toString();
  }
}
