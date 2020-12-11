import 'utils.dart';

bool contains(Object? values, Object? value) {
  if (values is String) {
    if (value is Pattern) {
      return values.contains(value);
    }

    throw TypeError();
  }

  if (values is Iterable<Object?>) {
    return values.contains(value);
  }

  if (values is Map<Object?, Object?>) {
    return values.containsKey(value);
  }

  return unsafeCast<dynamic>(values).conrains(value);
}

bool defined(Object? value) {
  if (value == null) {
    return false;
  }

  return true;
}

bool equal(Object? value, Object? other) {
  return value == other;
}

bool greaterThanOrEqual(Object? value, Object? other) {
  return unsafeCast<dynamic>(value) >= other;
}

bool greaterThan(Object? value, Object? other) {
  return unsafeCast<dynamic>(value) > other;
}

bool lessThanOrEqual(Object? value, Object? other) {
  return unsafeCast<dynamic>(value) <= other;
}

bool lessThan(Object? value, Object? other) {
  return unsafeCast<dynamic>(value) < other;
}

bool notEqual(Object? value, Object? other) {
  return value != other;
}

const tests = <String, Function>{
  '!=': notEqual,
  '<': lessThan,
  '<=': lessThanOrEqual,
  '==': equal,
  '>': greaterThan,
  '>=': greaterThanOrEqual,
  'defined': defined,
  'eq': equal,
  'equalto': equal,
  'ge': greaterThanOrEqual,
  'in': contains,
  'le': lessThanOrEqual,
  'lessthan': lessThan,
  'lt': lessThan,
  'gt': greaterThan,
  'greaterthan': greaterThan,
  'ne': notEqual,
  // 'callable': isCallable,
  // 'divisibleby': isDivisibleBy,
  // 'escaped': isEscaped,
  // 'even': isEven,
  // 'iterable': isIterable,
  // 'lower': isLower,
  // 'mapping': isMapping,
  // 'none': isNone,
  // 'number': isNumber,
  // 'odd': isOdd,
  // 'sameas': isSameAs,
  // 'sequence': isSequence,
  // 'string': isString,
  // 'undefined': isUndefined,
  // 'upper': isUpper,
};
