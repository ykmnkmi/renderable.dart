import 'anotations.dart';

@Test()
bool defined(Object value) {
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
