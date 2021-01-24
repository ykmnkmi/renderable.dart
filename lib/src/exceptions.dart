abstract class TemplateError implements Exception {
  TemplateError([this.message]);

  final dynamic message;

  @override
  String toString() {
    if (message == null) {
      return 'TemplateError';
    }

    return 'TemplateError: $message';
  }
}

class TemplateSyntaxError extends TemplateError {
  TemplateSyntaxError(String message, {this.line, this.name, this.fileName}) : super(message);

  final int? line;

  final String? name;

  final String? fileName;

  @override
  String toString() {
    var prefix = 'TemplateSyntaxError';
    var name = this.name ?? fileName;

    if (name != null) {
      if (prefix.contains(',')) {
        prefix += ', file: $name';
      }

      prefix += ' file: $name';
    }

    if (line != null) {
      if (prefix.contains(',')) {
        prefix += ', line: $line';
      } else {
        prefix += ' line: $line';
      }
    }

    return '$prefix: $message';
  }
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([dynamic message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'TemplateRuntimeError';
    }

    return 'TemplateRuntimeError: $message';
  }
}

/// This error is raised if a filter was called with inappropriate arguments.
class FilterArgumentError extends TemplateRuntimeError {
  FilterArgumentError([dynamic message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'FilterArgumentError';
    }

    return 'FilterArgumentError: $message';
  }
}
