String repr(Object object, [bool reprString = true]) {
  if (object is Iterable<Object>) {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(object.map<String>(repr), ', ');
    buffer.write(']');
    return buffer.toString();
  } else if (object is Map<Object, Object>) {
    final buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(object.entries.map<String>((entry) {
      final key = repr(entry.key);
      final value = repr(entry.value);
      return '$key: $value';
    }), ', ');
    buffer.write('}');
    return buffer.toString();
  } else if (object is String) {
    if (reprString) {
      final string = object.replaceAll('\'', '\\\'');
      return "'$string'";
    }

    return object;
  } else {
    return object.toString();
  }
}

bool toBool(Object value) {
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
