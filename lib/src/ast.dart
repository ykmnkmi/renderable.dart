library ast;

import 'visitor.dart';

part 'ast/interpolation.dart';
part 'ast/text.dart';
part 'ast/variable.dart';

part 'ast/expressions/test.dart';

part 'ast/statements/if.dart';

abstract class Node {
  static Node orList(List<Node> nodes) {
    if (nodes.length == 1) {
      return nodes[0];
    }

    return Interpolation(nodes);
  }

  void accept(Visitor visitor);
}

abstract class Expression extends Node {}

abstract class Statement extends Node {}
