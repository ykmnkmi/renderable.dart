bool defined(Object? value) {
  if (value == null) {
    return false;
  }

  return true;
}

const tests = <String, Function>{
  'defined': defined,
};