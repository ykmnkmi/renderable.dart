import 'package:meta/meta.dart';

@immutable
class Environment {
  const Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.expressionStart = '{{',
    this.expressionEnd = '}}',
    this.statementStart = '{%',
    this.statementEnd = '%}',
  })  : assert(commentStart != commentEnd),
        assert(expressionStart != expressionEnd),
        assert(statementStart != expressionEnd);

  factory Environment.fromMap(Map<String, Object> config) {
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

    return Environment(
      commentStart: commentStart,
      commentEnd: commentEnd,
      expressionStart: expressionStart,
      expressionEnd: expressionEnd,
      statementStart: statementStart,
      statementEnd: statementEnd,
    );
  }

  final String commentStart;

  final String commentEnd;

  final String expressionStart;

  final String expressionEnd;

  final String statementStart;

  final String statementEnd;

  Environment change({
    String commentStart,
    String commentEnd,
    String expressionStart,
    String expressionEnd,
    String statementStart,
    String statementEnd,
  }) {
    return Environment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      expressionStart: expressionStart ?? this.expressionStart,
      expressionEnd: expressionEnd ?? this.expressionEnd,
      statementStart: statementStart ?? this.statementStart,
      statementEnd: statementEnd ?? this.statementEnd,
    );
  }
}
