abstract class Renderable<C> {
  /// `path` xor `template`
  const factory Renderable({String path, String template}) = Generated<C>;

  String render([C context]);
}

class Generated<C> implements Renderable<C> {
  final String path;

  final String template;

  const Generated({this.path, this.template});

  @override
  int get hashCode => runtimeType.hashCode ^ path.hashCode;

  @override
  bool operator ==(Object other) => other is Generated && path == other.path;

  @override
  String render([C context]) {
    // TODO: add error message
    throw UnsupportedError('');
  }
}
