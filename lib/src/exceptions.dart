abstract class TemplateError implements Exception {
  TemplateError([this.error, this.stack]);

  final Object? error;

  final StackTrace? stack;

  @override
  String toString() {
    if (error == null) {
      return 'TemplateError';
    }

    return 'TemplateError: $error\n$stack';
  }
}

class TemplateSyntaxError extends TemplateError {
  TemplateSyntaxError(Object error, {this.offset, this.name, this.fileName}) : super(error, StackTrace.current);

  final int? offset;

  final String? name;

  final String? fileName;

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

    return '$prefix: $error\n$stack';
  }
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([Object? error, StackTrace? stack]) : super(error, stack ?? StackTrace.current);
}
