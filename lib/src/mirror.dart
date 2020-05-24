import 'dart:mirrors';

T getField<T>(String field, Object object) {
  if (object == null) {
    return null;
  }

  return reflect(object).getField(Symbol(field)) as T;
}
