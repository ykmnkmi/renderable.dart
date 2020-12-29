import 'markup.dart';
import 'utils.dart';

bool callable(dynamic object) {
  return object is Function;
}

bool contains(dynamic value, dynamic values) {
  if (values is String) {
    if (value is Pattern) {
      return values.contains(value);
    }

    throw TypeError();
  }

  if (values is Iterable) {
    return values.contains(value);
  }

  if (values is Map) {
    return values.containsKey(value);
  }

  return values.contains(value) as bool;
}

bool defined(dynamic value) {
  return boolean(value);
}

bool divisibleBy(num value, num divider) {
  return divider == 0 ? false : value % divider == 0;
}

bool equal(dynamic value, dynamic other) {
  return value == other;
}

bool escaped(dynamic value) {
  if (value is Markup) {
    return true;
  }

  return false;
}

bool even(int value) {
  return value.isEven;
}

bool greaterThanOrEqual(dynamic value, dynamic other) {
  return (value >= other) as bool;
}

bool greaterThan(dynamic value, dynamic other) {
  return (value > other) as bool;
}

bool iterable(dynamic value) {
  if (value is Iterable<dynamic>) {
    return true;
  }

  return false;
}

bool lessThanOrEqual(dynamic value, dynamic other) {
  return (value <= other) as bool;
}

bool lessThan(dynamic value, dynamic other) {
  return (value < other) as bool;
}

bool lower(String value) {
  return value == value.toLowerCase();
}

bool mapping(dynamic value) {
  if (value is Map) {
    return true;
  }

  return false;
}

bool none(dynamic value) {
  if (value == null) {
    return true;
  }

  return false;
}

bool notEqual(dynamic value, dynamic other) {
  return value != other;
}

bool number(dynamic object) {
  return object is num;
}

bool odd(int value) {
  return value.isOdd;
}

bool sameAs(dynamic value, dynamic other) {
  return identical(value, other);
}

bool sequence(dynamic value) {
  try {
    return value.length != null;
  } catch (e) {
    return false;
  }
}

bool string(dynamic object) {
  return object is String;
}

bool upper(String value) {
  return value == value.toUpperCase();
}

const tests = <String, Function>{
  '!=': notEqual,
  '<': lessThan,
  '<=': lessThanOrEqual,
  '==': equal,
  '>': greaterThan,
  '>=': greaterThanOrEqual,
  'callable': callable,
  'defined': defined,
  'divisibleby': divisibleBy,
  'eq': equal,
  'equalto': equal,
  'escaped': escaped,
  'even': even,
  'ge': greaterThanOrEqual,
  'in': contains,
  'iterable': iterable,
  'le': lessThanOrEqual,
  'lessthan': lessThan,
  'lt': lessThan,
  'gt': greaterThan,
  'greaterthan': greaterThan,
  'lower': lower,
  'mapping': mapping,
  'none': none,
  'ne': notEqual,
  'number': number,
  'odd': odd,
  'sameas': sameAs,
  'sequence': sequence,
  'string': string,
  'undefined': none,
  'upper': upper,
};
