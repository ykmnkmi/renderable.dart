// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RenedererGenerator
// **************************************************************************

import 'package:renderable/renderable.dart';

import 'example.dart';

const _UserRenderer userRenderer = _UserRenderer();

class _UserRenderer implements Renderable<User> {
  const _UserRenderer();

  @override
  String render([User context]) => 'hello ${context.name}!';
}

extension UserRenderer on User {
  String render() => userRenderer.render(this);
}
