import 'dart:mirrors' show reflect;

Object? apply(Object? object, List<Object?> positional, [Map<Symbol, Object?> named = const <Symbol, Object?>{}]) {
  return reflect(object).invoke(#call, positional, named).reflectee;
}

Object? getField(Object? object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}
