import 'dart:mirrors';

import 'jinja.dart';

dynamic getField(dynamic object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}

dynamic callCallable(dynamic object, List<dynamic> positional, [Map<Symbol, dynamic> named = const <Symbol, dynamic>{}]) {
  return reflect(object).invoke(#call, positional, named).reflectee;
}

/// Shorthand for call `Template.render` with given named arguments.
///
///     String render(Template, name: 'jhon', ...)
///
/// similar to
///
///     String Template.render({name: 'jhon', ...})
const dynamic render = RenderWrapper();

class RenderWrapper {
  const RenderWrapper();

  String call(Template template) {
    return template.render();
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final template = invocation.positionalArguments.first as Template;
      final map = <String, Object?>{};

      for (final symbol in invocation.namedArguments.keys) {
        map[MirrorSystem.getName(symbol)] = invocation.namedArguments[symbol];
      }

      return template.render(map);
    }

    return super.noSuchMethod(invocation);
  }
}
