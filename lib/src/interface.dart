class Generated<C> implements Renderable<C> {
  final String path;

  final String template;

  const Generated({this.path, this.template});

  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is Generated && path == other.path;
  }

  @override
  String render([C context]) {
    // TODO: текст ошибки
    throw UnsupportedError('');
  }
}

abstract class Renderable<C> {
  const factory Renderable({String path, String template}) = Generated<C>;

  String render([C context]);
}

class Isolated {
  final String method;

  const Isolated(this.method);
}
