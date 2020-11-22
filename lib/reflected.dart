import 'package:renderable/renderer.dart';

class Environment extends Configuration {
  Environment({
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
  })  : filters = <String, Function>{},
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
        ) {}

  final Map<String, Function> filters;

  final Map<String, Function> tests;
}

class Template extends Renderable {
  Template({String name}) : super(name: name) {}

  @override
  String render([Map<String, Object> context]) {}
}
