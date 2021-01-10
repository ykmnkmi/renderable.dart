import 'dart:math' show Random;

import 'package:meta/meta.dart';

import 'defaults.dart' as defaults;

typedef Finalizer = dynamic Function(dynamic value);

@immutable
class Configuration {
  Configuration(
      {this.commentBegin = '{#',
      this.commentEnd = '#}',
      this.variableBegin = '{{',
      this.variableEnd = '}}',
      this.blockBegin = '{%',
      this.blockEnd = '%}',
      this.lineCommentPrefix = '##',
      this.lineStatementPrefix = '#',
      this.lStripBlocks = false,
      this.trimBlocks = false,
      this.newLine = '\n',
      this.keepTrailingNewLine = false,
      this.optimized = true,
      this.finalize = defaults.finalize,
      this.autoEscape = false,
      Random? random,
      this.globals = const <String, dynamic>{},
      this.filters = const <String, Function>{},
      this.environmentFilters = const <String>{},
      this.tests = const <String, Function>{}})
      : random = Random();

  final String commentBegin;

  final String commentEnd;

  final String variableBegin;

  final String variableEnd;

  final String blockBegin;

  final String blockEnd;

  final String lineCommentPrefix;

  final String lineStatementPrefix;

  final bool lStripBlocks;

  final bool trimBlocks;

  final String newLine;

  final bool keepTrailingNewLine;

  final bool optimized;

  final Finalizer finalize;

  final bool autoEscape;

  final Random random;

  final Map<String, dynamic> globals;

  final Map<String, Function> filters;

  final Set<String> environmentFilters;

  final Map<String, Function> tests;

  Configuration copy(
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
      Set<String>? environmentFilters,
      Map<String, Function>? tests}) {
    return Configuration(
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
      random: random ?? this.random,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      environmentFilters: environmentFilters ?? this.environmentFilters,
      tests: tests ?? this.tests,
    );
  }
}
