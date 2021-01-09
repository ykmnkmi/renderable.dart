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
        throw NoSuchMethodError.withInvocation(this, Invocation.getter(Symbol(key)));
    }
  }

  Object cycle([Object? arg01, Object? arg02, Object? arg03, Object? arg04, Object? arg05, Object? arg06, Object? arg07, Object? arg08, Object? arg09]) {
    final values = <Object>[];

    if (arg01 != null) {
      values.add(arg01);

      if (arg02 != null) {
        values.add(arg02);

        if (arg03 != null) {
          values.add(arg03);

          if (arg04 != null) {
            values.add(arg04);

            if (arg05 != null) {
              values.add(arg05);

              if (arg06 != null) {
                values.add(arg06);

                if (arg07 != null) {
                  values.add(arg07);

                  if (arg08 != null) {
                    values.add(arg08);

                    if (arg09 != null) {
                      values.add(arg09);

                      // wanna more?
                      // look ath this https://api.flutter.dev/flutter/dart-ui/hashValues.html
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    if (values.isEmpty) {
      throw TypeError(/* no items for cycling given */);
    }

    return values[index0 % values.length];
  }
}

class RecursiveLoopContext extends LoopContext {
  RecursiveLoopContext(int index0, int length, dynamic previtem, dynamic nextitem, bool Function(dynamic) changed, this.render)
      : super(index0, length, previtem, nextitem, changed);

  final void Function(dynamic data) render;

  void call(dynamic data) {
    render(data);
  }
}

class Namespace {
  static Namespace factory([List<dynamic>? datas]) {
    if (datas == null) {
      return Namespace();
    }

    final context = <String, dynamic>{};

    for (final data in datas) {
      if (data is Map) {
        context.addAll(data.cast<String, dynamic>());
      } else {
        throw TypeError();
      }
    }

    return Namespace(context);
  }

  Namespace([Map<String, dynamic>? context]) : context = <String, dynamic>{} {
    if (context != null) {
      this.context.addAll(context);
    }
  }

  final Map<String, dynamic> context;

  Iterable<MapEntry<String, dynamic>> get entries {
    return context.entries;
  }

  dynamic operator [](String key) {
    return context[key];
  }

  void operator []=(String key, dynamic value) {
    context[key] = value;
  }

  @override
  String toString() {
    return 'Namespace($context)';
  }
}

class NSRef {
  NSRef(this.name, this.attribute);

  String name;

  String attribute;

  @override
  String toString() {
    return 'NSRef($name, $attribute)';
  }
}
