import 'dart:mirrors';

T getField<T>(Object object, String field) {
  if (object == null) {
    return null;
  }

  return reflect(object).getField(Symbol(field)) as T;
}
