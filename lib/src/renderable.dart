abstract class Renderable {
  const Renderable();

  Iterable<String> generate();

  String render();

  Stream<String> stream([Map<String, Object?>? data]);
}
