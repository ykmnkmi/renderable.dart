abstract class TemplateError implements Exception {
  TemplateError([this.message]);

  final String message;

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

  final int offset;

  final String name;

  final String fileName;

  @override
  String toString() {
    var prefix = 'TemplateSyntaxError';
    var name = this.name ?? fileName;

    if (name != null) {
      prefix += ', file: $name';
    }

    if (offset != null) {
      prefix += ', offset: $offset';
    }

    return '$prefix: $message';
  }
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([String message]) : super(message);
}
