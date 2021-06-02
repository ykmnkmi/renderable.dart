import 'package:meta/meta.dart';

import 'enirvonment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'runtime.dart';
import 'utils.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, {Map<String, Object?>? data, StringBuffer? buffer})
      : buffer = buffer ?? StringBuffer(),
        super(environment, data);

  RenderContext.from(Context context, {StringBuffer? buffer})
      : buffer = buffer ?? StringBuffer(),
        super.from(context);

  final StringBuffer buffer;

  Object? finalize(Object? object) {
    return environment.finalize(this, object);
  }

  bool remove(String name) {
    for (final context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  void set(String key, Object? value) {
    contexts.last[key] = value is Undefined ? null : value;
  }

  void write(Object? object) {
    buffer.write(object);
  }
}

class StringBufferRenderer extends ExpressionResolver<RenderContext> {
  @literal
  const StringBufferRenderer();

  @override
  void visitAll(List<Node> nodes, [RenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign node, [RenderContext? context]) {
    final target = node.target.accept(this, context);
    final values = node.expression.accept(this, context);
    assignTargetsToContext(context!, target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, [RenderContext? context]) {
    context!;

    final target = node.target.accept(this, context);
    final assignContext = RenderContext.from(context);
    visitAll(node.nodes, assignContext);
    Object? value = assignContext.buffer.toString();

    if (node.filters == null || node.filters!.isEmpty) {
      assignTargetsToContext(context, target, context.escaped(value));
      return;
    }

    for (final filter in node.filters!) {
      value = callFilter(filter, value, context);
    }

    assignTargetsToContext(context, target, context.escaped(value));
  }

  @override
  void visitBlock(Block node, [RenderContext? context]) {
    visitAll(node.nodes, context);
  }

  @override
  void visitDo(Do node, [RenderContext? context]) {
    final doContext = Context.from(context!);

    for (final expression in node.expressions) {
      expression.accept(this, doContext);
    }
  }

  @override
  void visitFor(For node, [RenderContext? context]) {
    context!;

    final targets = node.target.accept(this, context);
    final iterable = node.iterable.accept(this, context);
    final orElse = node.orElse;

    if (iterable == null) {
      throw TypeError();
    }

    String recurse(Object? iterable, [int depth = 0]) {
      var values = list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, context);
        }

        return '';
      }

      if (node.test != null) {
        final test = node.test!;
        final filtered = <Object?>[];

        for (final value in values) {
          final data = getDataForTargets(targets, value);
          context.push(data);

          if (test.accept(this, context) as bool) {
            filtered.add(value);
          }

          context.pop();
        }

        values = filtered;
      }

      final loop = LoopContext(values, context.environment.undefined, depth0: depth, recurse: recurse);
      Map<String, Object?> Function(Object?, Object?) unpack;

      if (node.hasLoop) {
        unpack = (Object? target, Object? value) {
          final data = getDataForTargets(target, value);
          data['loop'] = loop;
          return data;
        };
      } else {
        unpack = getDataForTargets;
      }

      for (final value in loop) {
        final data = unpack(targets, value);
        context.push(data);
        visitAll(node.body, context);
        context.pop();
      }

      return '';
    }

    recurse(iterable);
  }

  @override
  void visitIf(If node, [RenderContext? context]) {
    context!;

    if (boolean(node.test.accept(this, context))) {
      visitAll(node.body, context);
      return;
    }

    var next = node.nextIf;

    while (next != null) {
      if (boolean(next.test.accept(this, context))) {
        visitAll(next.body, context);
        return;
      }

      next = next.nextIf;
    }

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }
  }

  @override
  void visitInclude(Include node, [RenderContext? context]) {
    context!;

    try {
      final template = context.environment.getTemplate(node.template);

      if (node.withContext) {
        template.accept(this, context);
      } else {
        template.accept(this, RenderContext(context.environment, buffer: context.buffer));
      }
    } on TemplateNotFound {
      if (!node.ignoreMissing) {
        rethrow;
      }
    }
  }

  @override
  void visitOutput(Output node, [RenderContext? context]) {
    context!;

    for (final item in node.nodes) {
      if (item is Data) {
        context.write(item.accept(this, context));
      } else {
        var value = item.accept(this, context);
        value = context.escape(value);
        value = context.finalize(value);
        context.write(value);
      }
    }
  }

  @override
  void visitScope(Scope node, [RenderContext? context]) {
    node.modifier.accept(this, context);
  }

  @override
  void visitScopedContextModifier(ScopedContextModifier node, [RenderContext? context]) {
    context!;

    final data = {for (final key in node.options.keys) key: node.options[key]!.accept(this)};
    context.apply<RenderContext>(data, (context) {
      visitAll(node.nodes, context);
    });
  }

  @override
  void visitTemplate(Template node, [RenderContext? context]) {
    context!;

    for (final block in node.blocks) {
      if (context.blocks.containsKey(block.name)) {
        context.blocks[block.name]!.parent = BlockReference(block);
      } else {
        context.blocks[block.name] = BlockReference(block);
      }
    }

    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, [RenderContext? context]) {
    context!;

    final targets = node.targets.map((target) => target.accept(this, context)).toList();
    final values = node.values.map((value) => value.accept(this, context)).toList();

    context.push(getDataForTargets(targets, values));
    visitAll(node.body, context);
    context.pop();
  }

  @protected
  static void assignTargetsToContext(RenderContext context, Object? target, Object? current) {
    if (target is String) {
      context.set(target, current);
      return;
    }

    if (target is List<String>) {
      List<Object?> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable<Object?>) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < target.length) {
        throw StateError('not enough values to unpack (expected ${target.length}, got ${list.length})');
      }

      if (list.length > target.length) {
        throw StateError('too many values to unpack (expected ${target.length})');
      }

      for (var i = 0; i < target.length; i++) {
        context.set(target[i], list[i]);
      }

      return;
    }

    if (target is NamespaceValue) {
      final namespace = context[target.name];

      if (namespace is! Namespace) {
        throw TemplateRuntimeError('non-namespace object');
      }

      namespace[target.item] = current;
      return;
    }

    throw ArgumentError.value(target, 'target');
  }

  @protected
  static Map<String, Object?> getDataForTargets(Object? target, Object? current) {
    if (target is String) {
      return <String, Object?>{target: current};
    }

    if (target is List) {
      final names = target.cast<String>();
      List<Object?> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < names.length) {
        throw StateError('not enough values to unpack (expected ${names.length}, got ${list.length})');
      }

      if (list.length > names.length) {
        throw StateError('too many values to unpack (expected ${names.length})');
      }

      final data = <String, Object?>{};

      for (var i = 0; i < names.length; i++) {
        data[names[i]] = list[i];
      }

      return data;
    }

    throw ArgumentError.value(target, 'target');
  }
}
