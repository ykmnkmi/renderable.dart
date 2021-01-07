class LoopContext {
  LoopContext(this.index0, this.length, this.previtem, this.nextitem, this.changed)
      : index = index0 + 1,
        first = index0 == 0,
        last = index0 + 1 == length,
        revindex = length - index0,
        revindex0 = length - index0 - 1,
        cycle = CycleWrapper(index0);

  final int index0;

  final int length;

  final dynamic previtem;

  final dynamic nextitem;

  final bool Function(dynamic) changed;

  final int index;

  final bool first;

  final bool last;

  final int revindex;

  final int revindex0;

  final CycleWrapper cycle;

  dynamic operator [](String key) {
    switch (key) {
      case 'index0':
        return index0;
      case 'length':
        return length;
      case 'previtem':
        return previtem;
      case 'nextitem':
        return nextitem;
      case 'changed':
        return changed;
      case 'index':
        return index;
      case 'first':
        return first;
      case 'last':
        return last;
      case 'revindex':
        return revindex;
      case 'revindex0':
        return revindex0;
      case 'cycle':
        return cycle;
      default:
        throw NoSuchMethodError.withInvocation(this, Invocation.getter(Symbol(key)));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #cycle) {
      return cycle(invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}

class RecursiveLoopContext extends LoopContext {
  RecursiveLoopContext(int index0, int length, dynamic previtem, dynamic nextitem, bool Function(dynamic) changed, this.render)
      : super(index0, length, previtem, nextitem, changed);

  final void Function(dynamic data) render;

  void call(dynamic data) {
    render(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return Function.apply(render, invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}

class CycleWrapper {
  CycleWrapper(this.index);

  final int index;

  dynamic call(List<dynamic> arguments) {
    return arguments[index % arguments.length];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return call(invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}
