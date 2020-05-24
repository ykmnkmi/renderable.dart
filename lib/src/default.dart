import 'util.dart';

export 'mirror.dart' show getField;

Object finalizer(Object value) {
  value ??= '';

  if (value is String) {
    return value;
  }

  return repr(value, false);
}
