class LoopContext {
  LoopContext(int index0, int length, dynamic previtem, dynamic nextitem, Function changed)
      : data = <String, dynamic>{
          'index0': index0,
          'length': length,
          'previtem': previtem,
          'nextitem': nextitem,
          'changed': changed,
          'index': index0 + 1,
          'first': index0 == 0,
          'last': index0 + 1 == length,
          'revindex': length - index0,
          'revindex0': length - index0 - 1,
          'cycle': CycleWrapper((args) => args[index0 % args.length])
        };

  final Map<String, dynamic> data;

  dynamic operator [](String key) {
    return data[key]!;
  }
}

class CycleWrapper {
  CycleWrapper(this.function);

  final dynamic Function(List<dynamic> values) function;

  dynamic call();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.positionalArguments[0] as List);
    }

    return super.noSuchMethod(invocation);
  }
}
