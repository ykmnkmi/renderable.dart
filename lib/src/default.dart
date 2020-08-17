import 'util.dart';

Object getItem(Map<String, Object> map, String key) {
  return map[key];
}

Object getField(Object instance, String field) {
  throw UnimplementedError();
}

Object finalizer(Object value) {
  value ??= '';

  if (value is String) {
    return value;
  }

  return repr(value, false);
}
