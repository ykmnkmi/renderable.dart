import 'dart:mirrors' show MirrorSystem, reflect;

import 'jinja.dart';

dynamic apply(dynamic object, List<dynamic> positional, [Map<Symbol, dynamic> named = const {}]) {
  return reflect(object).invoke(#call, positional, named).reflectee;
}

dynamic getField(dynamic object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}

/// Shorthand for call [Template.render] with given named arguments.
///
/// **Note: uses _dart:mirrors_.**
///
///     String render(Template, name: 'jhon', ...)
///
/// similar to
///
///     String Template.render({name: 'jhon', ...})
const dynamic render = _RenderWrapper();

class _RenderWrapper {
  const _RenderWrapper();

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
