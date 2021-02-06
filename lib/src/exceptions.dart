/// Baseclass for all template errors.
abstract class TemplateError implements Exception {
  TemplateError([this.message]);

  final Object? message;

  @override
  String toString() {
    if (message == null) {
      return '$runtimeType';
    }

    return '$runtimeType: $message';
  }
}

/// Raised to tell the user that there is a problem with the template.
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

/// A generic runtime error in the template engine.
///
/// Under some situations Jinja may raise this exception.
class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([Object? message]) : super(message);
}

/// Raised if a template tries to operate on [Undefined].
class UndefinedError extends TemplateRuntimeError {
  UndefinedError([Object? message]) : super(message);
}

/// This error is raised if a filter was called with inappropriate arguments.
class FilterArgumentError extends TemplateRuntimeError {
  FilterArgumentError([Object? message]) : super(message);
}
