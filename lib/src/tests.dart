import 'markup.dart';
import 'utils.dart' as utils;

bool isBoolean(dynamic object) {
  return object is bool;
}

bool isCallable(dynamic object) {
  return object is Function;
}

bool isDefined(dynamic value) {
  return utils.boolean(value);
}

bool isDivisibleBy(num value, num divider) {
  return divider == 0 ? false : value % divider == 0;
}

bool isEqual(dynamic value, dynamic other) {
  return value == other;
}

bool isEscaped(dynamic value) {
  if (value is Markup) {
    return true;
  }

  return false;
}

bool isEven(int value) {
  return value.isEven;
}

bool isFalse(dynamic value) {
  return value == false;
}

bool isFloat(dynamic value) {
  return value is double;
}

bool isGreaterThanOrEqual(dynamic value, dynamic other) {
  return (value >= other) as bool;
}

bool isGreaterThan(dynamic value, dynamic other) {
  return (value > other) as bool;
}

bool isIn(dynamic value, dynamic values) {
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

bool isInteger(dynamic value) {
  return value is int;
}

bool iterable(dynamic value) {
  if (value is Iterable<dynamic>) {
    return true;
  }

  return false;
}

bool isLessThanOrEqual(dynamic value, dynamic other) {
  return (value <= other) as bool;
}

bool isLessThan(dynamic value, dynamic other) {
  return (value < other) as bool;
}

bool isLower(String value) {
  return value == value.toLowerCase();
}

bool isMapping(dynamic value) {
  if (value is Map) {
    return true;
  }

  return false;
}

bool isNone(dynamic value) {
  if (value == null) {
    return true;
  }

  return false;
}

bool isNotEqual(dynamic value, dynamic other) {
  return value != other;
}

bool isNumber(dynamic object) {
  return object is num;
}

bool isOdd(int value) {
  return value.isOdd;
}

bool isSameAs(dynamic value, dynamic other) {
  return identical(value, other);
}

bool isSequence(dynamic value) {
  try {
    return value.length != null;
  } catch (e) {
    return false;
  }
}

bool isString(dynamic object) {
  return object is String;
}

bool isTrue(dynamic value) {
  return value == true;
}

bool isUpper(String value) {
  return value == value.toUpperCase();
}

const Map<String, Function> tests = {
  '!=': isNotEqual,
  '<': isLessThan,
  '<=': isLessThanOrEqual,
  '==': isEqual,
  '>': isGreaterThan,
  '>=': isGreaterThanOrEqual,
  'boolean': isBoolean,
  'callable': isCallable,
  'defined': isDefined,
  'divisibleby': isDivisibleBy,
  'eq': isEqual,
  'equalto': isEqual,
  'escaped': isEscaped,
  'even': isEven,
  'false': isFalse,
  'float': isFloat,
  'ge': isGreaterThanOrEqual,
  'greaterthan': isGreaterThan,
  'gt': isGreaterThan,
  'in': isIn,
  'integer': isInteger,
  'iterable': iterable,
  'le': isLessThanOrEqual,
  'lessthan': isLessThan,
  'lower': isLower,
  'lt': isLessThan,
  'mapping': isMapping,
  'ne': isNotEqual,
  'none': isNone,
  'number': isNumber,
  'odd': isOdd,
  'sameas': isSameAs,
  'sequence': isSequence,
  'string': isString,
  'true': isTrue,
  'undefined': isNone,
  'upper': isUpper,
};
