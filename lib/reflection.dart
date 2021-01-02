import 'dart:mirrors';

dynamic getField(dynamic object, String field) {
  final mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}
