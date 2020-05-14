import 'dart:mirrors';

T getField<T>(String field, Object object) => reflect(object).getField(Symbol(field)) as T;
