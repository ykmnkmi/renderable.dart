import 'context.dart';
import 'enirvonment.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'runtime.dart';
import 'utils.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink, [Map<String, dynamic>? data]) : super(environment, data);

  final StringSink sink;
}

class Renderer extends ExpressionResolver<RenderContext> {
  const Renderer(this.environment);

  final Environment environment;

  String render(List<Node> nodes, [Map<String, dynamic>? data]) {
    final buffer = StringBuffer();
    visitAll(nodes, RenderContext(environment, buffer, data));
    return buffer.toString();
  }

  @override
  void visitAll(List<Node> nodes, [RenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitData(Data data, [RenderContext? context]) {
    context!.sink.write(data.data);
  }

  @override
  void visitFor(For forNode, [RenderContext? context]) {
    final kontext = context!;

    final targets = forNode.target.accept(this, kontext) as List<String>;

    if (forNode.hasLoop && targets.contains('loop')) {
      throw StateError('can\'t assign to special loop variable in for-loop target');
    }

    final iterable = forNode.iterable.accept(this, kontext);
    final orElse = forNode.orElse;

    if (iterable == null) {
      if (orElse == null) {
        throw TypeError();
      } else {
        visitAll(orElse, kontext);
        return;
      }
    }

    void render(dynamic iterable) {
      late List<dynamic> list;

      if (iterable is List) {
        list = iterable;
      } else if (iterable is Iterable) {
        list = iterable.toList();
      } else if (iterable is String) {
        list = iterable.split('');
      } else if (iterable is Map) {
        list = iterable.entries.map((entry) => [entry.key, entry.value]).toList();
      } else if (iterable != null) {
        throw TypeError();
      }

      if (list.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, kontext);
        }

        return;
      }

      Map<String, dynamic> Function(List<dynamic>, int) unpack;

      Map<String, dynamic> assignTargets(List<dynamic> values, int index) {
        final current = values[index];

        if (targets.length == 1) {
          return <String, dynamic>{targets[0]: current};
        }

        final data = <String, dynamic>{};

        List<dynamic> list;

        if (current is List) {
          list = current;
        } else if (current is Iterable) {
          list = current.toList();
        } else if (current is String) {
          list = current.split('');
        } else {
          throw TypeError();
        }

        if (list.length < targets.length) {
          throw StateError('not enough values to unpack (expected ${targets.length}, got ${list.length})');
        }

        if (list.length > targets.length) {
          throw StateError('too many values to unpack (expected ${targets.length})');
        }

        for (var i = 0; i < targets.length; i++) {
          data[targets[i]] = list[i];
        }

        return data;
      }

      if (forNode.hasLoop) {
        unpack = (List<dynamic> values, int index) {
          final data = assignTargets(values, index);
          dynamic previous, next;

          if (index > 0) {
            previous = values[index - 1];
          }

          if (index < values.length - 1) {
            next = values[index + 1];
          }

          bool changed(dynamic item) {
            if (index == 0) {
              return true;
            }

            if (item == previous) {
              return false;
            }

            return true;
          }

          data['loop'] = forNode.recursive
              ? RecursiveLoopContext(index, values.length, previous, next, changed, render)
              : LoopContext(index, values.length, previous, next, changed);
          return data;
        };
      } else {
        unpack = assignTargets;
      }

      if (forNode.test != null) {
        final test = forNode.test!;
        final filtered = <dynamic>[];

        for (var i = 0; i < list.length; i += 1) {
          final data = unpack(list, i);
          kontext.push(data);

          if (test.accept(this, kontext) as bool) {
            filtered.add(list[i]);
          }

          kontext.pop();
        }

        list = filtered;
      }

      for (var i = 0; i < list.length; i += 1) {
        final data = unpack(list, i);
        kontext.push(data);
        visitAll(forNode.body, kontext);
        kontext.pop();
      }
    }

    render(iterable);
  }

  @override
  void visitIf(If ifNode, [RenderContext? context]) {
    final kontext = context!;

    if (boolean(ifNode.test.accept(this, kontext))) {
      visitAll(ifNode.body, kontext);
      return;
    }

    var next = ifNode.nextIf;

    while (next != null) {
      if (boolean(next.test.accept(this, kontext))) {
        visitAll(next.body, kontext);
        return;
      }

      next = next.nextIf;
    }

    if (ifNode.orElse != null) {
      visitAll(ifNode.orElse!, kontext);
    }
  }

  @override
  void visitOutput(Output output, [RenderContext? context]) {
    final kontext = context!;

    for (final node in output.nodes) {
      if (node is Data) {
        node.accept(this, kontext);
      } else {
        kontext.sink.write(kontext.environment.finalize(node.accept(this, kontext)));
      }
    }
  }
}
