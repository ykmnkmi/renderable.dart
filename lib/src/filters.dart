import 'package:renderable/anotations.dart';

@Filter()
bool boolean(Object value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0.0;
  }

  if (value is String) {
    return value.isNotEmpty;
  }

  if (value is Iterable<Object>) {
    return value.isNotEmpty;
  }

  if (value is Map<Object, Object>) {
    return value.isNotEmpty;
  }

  return true;
}

@Filter()
String string(Object value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  return value.toString();
}
