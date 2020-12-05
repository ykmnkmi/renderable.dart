bool boolean(Object? value) {
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

  if (value is Iterable) {
    return value.isNotEmpty;
  }

  if (value is Map) {
    return value.isNotEmpty;
  }

  return true;
}

String represent(Object? object) {
  if (object is Iterable<Object?>) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map<String>(represent), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map<Object?, Object?>) {
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

String string(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return value.toString();
}
