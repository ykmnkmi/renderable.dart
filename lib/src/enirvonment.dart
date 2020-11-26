import 'configuration.dart';
import 'filters.dart';
import 'nodes.dart';
import 'parser.dart';
import 'renderable.dart';
import 'renderer.dart';

typedef Finalizer = Object Function([Object value]);

Object defaultFinalizer([Object value]) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return represent(value);
}

class Environment extends Configuration {
  Environment({
    String blockBegin = '{%',
    String blockEnd = '%}',
    String variableBegin = '{{',
    String variableEnd = '}}',
    String commentBegin = '{#',
    String commentEnd = '#}',
    String lineCommentPrefix = '##',
    String lineStatementPrefix = '#',
    bool trimBlocks = false,
    bool lStripBlocks = false,
    String newLine = '\n',
    bool keepTrailingNewLine = false,
    this.finalize = defaultFinalizer,
    Map<String, Object> globals,
    Map<String, Function> filters,
    Map<String, Function> tests,
  })  : globals = <String, Object>{},
        filters = <String, Function>{},
        tests = <String, Function>{},
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
  }

  final Map<String, Object> globals;

  final Map<String, Function> filters;

  final Map<String, Function> tests;

  final Finalizer finalize;

  @override
  Environment change({
    String commentBegin,
    String commentEnd,
    String variableBegin,
    String variableEnd,
    String blockBegin,
    String blockEnd,
    String lineCommentPrefix,
    String lineStatementPrefix,
    bool lStripBlocks,
    bool trimBlocks,
    String newLine,
    bool keepTrailingNewLine,
    Finalizer finalize,
  }) {
    return Environment(
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
    );
  }
}

class Template extends Renderable {
  factory Template(
    String source, {
    String path,
    Environment parent,
    String commentBegin = '{#',
    String commentEnd = '#}',
    String variableBegin = '{{',
    String variableEnd = '}}',
    String blockBegin = '{%',
    String blockEnd = '%}',
    String lineCommentPrefix = '##',
    String lineStatementPrefix = '#',
    bool lStripBlocks = false,
    bool trimBlocks = false,
    String newLine = '\n',
    bool keepTrailingNewLine = false,
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
      );
    }

    final nodes = Parser(environment).parse(source, path: path);
    return Template.parsed(environment, nodes, path);
  }

  Template.parsed(this.environment, this.nodes, [this.path]);

  final Environment environment;

  final List<Node> nodes;

  final String path;

  @override
  String render([Map<String, Object> context]) {
    return Renderer(environment, nodes, context).toString();
  }
}
