String repr(Object object, [bool reprString = true]) {
  if (object is Iterable) {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(object.map<String>(repr), ', ');
    buffer.write(']');
    return buffer.toString();
  } else if (object is Map) {
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
