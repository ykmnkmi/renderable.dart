import 'package:meta/dart2js.dart';

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

List<T> slice<T>(List<T> list, int start, [int? stop, int? step]) {
  final result = <T>[];
  final length = list.length;

  if (stop == null) {
    stop = length;
  } else if (stop < 0) {
    stop = length - stop;
  }

  step ??= 1;

  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      result.add(list[i]);
    }
  } else if (step < 0) {
    step = step.abs();

    for (var i = start; i < stop; i -= step) {
      result.add(list[i]);
    }
  } else {
    throw ArgumentError.value(step, 'step');
  }

  return result;
}

@tryInline
@pragma('vm:prefer-inline')
T unsafeCast<T>(dynamic object) {
  // ignore: return_of_invalid_type
  return object;
}
