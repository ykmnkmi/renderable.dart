import 'dart:mirrors';

import 'package:renderable/src/exceptions.dart';

Object? getAttribute(Object? object, String attribute) {
  try {
    final field = reflect(object).getField(Symbol(attribute));
    return field.reflectee;
  } catch (error, stack) {
    // TODO: improve error message
    throw TemplateRuntimeError(error, stack);
  }
}
