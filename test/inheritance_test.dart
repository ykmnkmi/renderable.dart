import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

const String layout = '''|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|''';

const String level1 = '''{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}''';

const String level2 = '''{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}''';

const String level3 = '''{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}''';

const String level4 = '''{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}''';

const String working = '''{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const String doublee = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const Map<String, String> mapping = <String, String>{
  'layout': layout,
  'level1': level1,
  'level2': level2,
  'level3': level3,
  'level4': level4,
  'working': working,
  'doublee': doublee,
};

void main() {
  group('Inheritance', () {
    late Environment environment;

    setUpAll(() {
      environment = Environment(loader: MapLoader(mapping), trimBlocks: true);
    });

    test('layout', () {
      final template = environment.getTemplate('layout');
      expect(template.render(), equals('|block 1 from layout|block 2 from layout|nested block 4 from layout|'));
    });

    test('level1', () {
      final template = environment.getTemplate('level1');
      expect(template.render(), equals('|block 1 from level1|block 2 from layout|nested block 4 from layout|'));
    });

    test('level2', () {
      final template = environment.getTemplate('level2');
      expect(template.render(), equals('|block 1 from level1|nested block 5 from level2|nested block 4 from layout|'));
    });

    test('level3', () {
      final template = environment.getTemplate('level3');
      expect(template.render(), equals('|block 1 from level1|block 5 from level3|block 4 from level3|'));
    });

    test('level4', () {
      final template = environment.getTemplate('level4');
      expect(template.render(), equals('|block 1 from level1|block 5 from level3|block 3 from level4|'));
    });

    test('super', () {
      final environment = Environment(
        loader: MapLoader(<String, String>{
          'a': '{% block intro %}INTRO{% endblock %}|BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ super() }}--{% endblock %}\n{% block data %}[{{ super() }}]'
              '{% endblock %}',
        }),
      );

      final template = environment.getTemplate('c');
      expect(template.render(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });
  });
}
