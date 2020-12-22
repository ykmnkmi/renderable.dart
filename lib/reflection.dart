import 'dart:mirrors';

import 'package:renderable/src/exceptions.dart';

dynamic getAttribute(dynamic object, String attribute, [dynamic Function()? orElse]) {
  try {
    final field = reflect(object).getField(Symbol(attribute));

    if (field.hasReflectee) {
      return field.reflectee;
    }

    return null;
  } catch (error, stack) {
    if (orElse != null) {
      return orElse();
    }

    // TODO: improve error message
    throw TemplateRuntimeError(error, stack);
  }
}
