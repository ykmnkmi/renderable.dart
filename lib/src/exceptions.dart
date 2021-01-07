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
  TemplateSyntaxError(String message, {this.offset, this.name, this.fileName}) : super(message);

  final int? offset;

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

    if (offset != null) {
      if (prefix.contains(',')) {
        prefix += ', offset: $offset';
      }

      prefix += ' offset: $offset';
    }

    return '$prefix: $message';
  }
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([dynamic message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'TemplateRuntimeError()';
    }

    return 'TemplateRuntimeError($message)';
  }
}
