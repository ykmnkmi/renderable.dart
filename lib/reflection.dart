import 'dart:mirrors' show reflect;

Object? getField(Object? object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}
