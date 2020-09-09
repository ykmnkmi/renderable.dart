import 'dart:io';

import 'package:renderable/src/ast.dart';
import 'package:renderable/src/environment.dart';
import 'package:renderable/src/environment.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/visitor.dart';

void main(List<String> args) {
  if (args.isEmpty) return;
  
  final environment = const Environment();
  final node = Parser(environment).parse(File(args[0]).readAsStringSync(), path: args[0]);
  print(node);
}
