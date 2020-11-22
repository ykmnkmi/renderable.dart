String repr(Object object) {
  if (object is Iterable<Object>) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map<String>(repr), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map<Object, Object>) {
    final buffer = StringBuffer('{');
    final pairs = <Object>[];

    object.forEach((key, value) {
      pairs.add('${repr(key)}: ${repr(value)}');
    });

    buffer
      ..writeAll(pairs, ', ')
      ..write('}');
    return buffer.toString();
  } else if (object is String) {
    final string = object.replaceAll('\'', '\\\'');
    return "'$string'";
  } else {
    return object.toString();
  }
}
