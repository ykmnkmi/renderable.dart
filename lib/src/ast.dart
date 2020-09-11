library ast;

import 'visitor.dart';

part 'ast/interpolation.dart';
part 'ast/text.dart';
part 'ast/variable.dart';

part 'ast/statement/if.dart';

abstract class Node {
  static Node orList(List<Node> nodes) {
    if (nodes.length == 1) {
      return nodes[0];
    }

    return Interpolation(nodes);
  }

  R accept<C, R>(Visitor<C, R> visitor, [C context]);
}

abstract class Expression extends Node {}

abstract class Statement extends Node {}
