part of '../nodes.dart';

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOutput(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'Output(${nodes.join(', ')})';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body, {this.hasLoop = false, this.orElse});

  Expression target;

  Expression iterable;

  List<Node> body;

  bool hasLoop;

  List<Node>? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFor(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    visitor(iterable);
    body.forEach(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'For($target, $iterable, $body';

    if (orElse != null) {
      result += ', orElse: $orElse';
    }

    return result + ')';
  }
}

class If extends Statement {
  If(this.test, this.body, {this.nextIf, this.orElse});

  Expression test;

  List<Node> body;

  If? nextIf;

  List<Node>? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitIf(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(test);

    for (final node in body) {
      visitor(node);
    }

    nextIf?.visitChildNodes(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'If($test, $body';

    if (nextIf != null) {
      result += ', next: $nextIf';
    }

    if (orElse != null) {
      result += ', orElse: $orElse';
    }

    return result + ')';
  }
}
