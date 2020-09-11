String represent(dynamic object, [bool wrapString = true]) {
  if (object is Iterable) {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(object.map<String>(represent), ', ');
    buffer.write(']');
    return buffer.toString();
  } else if (object is Map) {
    final buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(object.entries.map<String>((entry) {
      final key = represent(entry.key);
      final value = represent(entry.value);
      return '$key: $value';
    }), ', ');
    buffer.write('}');
    return buffer.toString();
  } else if (object is String) {
    if (wrapString) {
      final string = object.replaceAll('\'', '\\\'');
      return "'$string'";
    }

    return object;
  } else {
    return object.toString();
  }
}
