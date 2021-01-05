import 'dart:mirrors';

dynamic getField(dynamic object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}

class RenderWrapper {
  static dynamic wrap(String Function([Map<String, dynamic>? data]) render) {
    return RenderWrapper(render);
  }

  RenderWrapper(this.render);

  final String Function([Map<String, dynamic>? data]) render;

  String call([Map<String, dynamic>? data]) {
    return render(data);
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final map = <String, Object?>{};

      for (final symbol in invocation.namedArguments.keys) {
        map[MirrorSystem.getName(symbol)] = invocation.namedArguments[symbol];
      }

      return render(map);
    }

    return super.noSuchMethod(invocation);
  }
}
