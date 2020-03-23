library parser;

import 'template.dart';

class Parser {
  const Parser();

  Template parse(String source) {
    return null;
  }
}

extension TemplateString on String {
  Template parse() => const Parser().parse(this);

  String render(Map<String, Object> context) => parse().render(context);
}
