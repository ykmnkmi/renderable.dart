part of '../nodes.dart';

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOutput(this, context);
  }

  @override
  String toString() {
    return 'Output($nodes)';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body);

  Expression target;

  Expression iterable;

  List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFor(this, context);
  }

  @override
  String toString() {
    return 'For($target, $iterable, $body)';
  }
}

class If extends Statement {
  If({Expression? test, List<Node>? body, this.elseIf, this.else_})
      : test = test ?? Constant.False,
        body = body ?? <Node>[];

  Expression test;

  List<Node> body;

  List<If>? elseIf;

  List<Node>? else_;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitIf(this, context);
  }

  @override
  String toString() {
    return 'If($test, $body, $elseIf, ${else_})';
  }
}
