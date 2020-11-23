String represent(Object object) {
  if (object is Iterable<Object>) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map<String>(represent), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map<Object, Object>) {
    final buffer = StringBuffer('{');
    final pairs = <Object>[];

    object.forEach((key, value) {
      pairs.add('${represent(key)}: ${represent(value)}');
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
