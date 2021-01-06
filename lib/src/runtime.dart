class LoopContext {
  LoopContext(this.index0, this.length, this.previtem, this.nextitem, this.changed)
      : index = index0 + 1,
        first = index0 == 0,
        last = index0 + 1 == length,
        revindex = length - index0,
        revindex0 = length - index0 - 1;

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
        return null;
    }
  }

  dynamic cycle(List<dynamic> arguments) {
    return arguments[index0 % arguments.length];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('hehehehehheehhe');
    if (invocation.memberName == #cycle) {
      return cycle(invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}
