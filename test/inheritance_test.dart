import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';

import 'core.dart';

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
      environment
          .getTemplate('layout')
          .render()
          .equals('|block 1 from layout|block 2 from layout|nested block 4 from layout|');
    });

    test('level1', () {
      environment
          .getTemplate('level1')
          .render()
          .equals('|block 1 from level1|block 2 from layout|nested block 4 from layout|');
    });

    test('level2', () {
      environment
          .getTemplate('level2')
          .render()
          .equals('|block 1 from level1|nested block 5 from level2|nested block 4 from layout|');
    });

    test('level3', () {
      environment
          .getTemplate('level3')
          .render()
          .equals('|block 1 from level1|block 5 from level3|block 4 from level3|');
    });

    test('level4', () {
      environment
          .getTemplate('level4')
          .render()
          .equals('|block 1 from level1|block 5 from level3|block 3 from level4|');
    });

    test('super', () {
      var environment = Environment(
        loader: MapLoader({
          'a': '{% block intro %}INTRO{% endblock %}|BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ super() }}--{% endblock %}\n{% block data %}[{{ super() }}]'
              '{% endblock %}',
        }),
      );

      environment.getTemplate('c').render().equals('--INTRO--|BEFORE|[(INNER)]|AFTER');
    });

    test('working', () {
      environment.getTemplate('working').render();
    });

    test('reusing blocks', () {
      environment
          .fromString('{{ self.foo() }}|{% block foo %}42{% endblock %}|{{ self.foo() }}')
          .render()
          .equals('42|42|42');
    });

    test('preserve blocks', () {
      var environment = Environment(
        loader: MapLoader({
          'a': '{% if false %}{% block x %}A{% endblock %}{% endif %}{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      environment.getTemplate('b').render().equals('BA');
    });

    test('scoped block', () {
      var environment = Environment(
        loader: MapLoader({'default.html': '{% for item in seq %}[{% block item scoped %}{% endblock %}]{% endfor %}'}),
      );

      var data = <String, Object?>{'seq': range(5)};
      environment
          .fromString('{% extends "default.html" %}{% block item %}{{ item }}{% endblock %}')
          .render(data)
          .equals('[0][1][2][3][4]');
    });

    test('super in scoped block', () {
      var environment = Environment(
        loader: MapLoader(<String, String>{
          'default.html': '{% for item in seq %}[{% block item scoped %}{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      var data = <String, Object?>{'seq': range(5)};
      environment
          .fromString('{% extends "default.html" %}{% block item %}{{ super() }}|{{ item * 2 }}{% endblock %}')
          .render(data)
          .equals('[0|0][1|2][2|4][3|6][4|8]');
    });

    // TODO: after macro: scoped block after inheritance
    test('scoped block after inheritance', () {
      var environment = Environment(
        loader: MapLoader(<String, String>{
          'layout.html': '{% block useless %}{% endblock %}',
          'index.html': '''
            {%- extends 'layout.html' %}
            {% from 'helpers.html' import foo with context %}
            {% block useless %}
                {% for x in [1, 2, 3] %}
                    {% block testing scoped %}
                        {{ foo(x) }}
                    {% endblock %}
                {% endfor %}
            {% endblock %}''',
          'helpers.html': '{% macro foo(x) %}{{ the_foo + x }}{% endmacro %}',
        }),
      );

      var data = <String, Object?>{'the_foo': 42};
      environment
          .getTemplate('index.html')
          .render(data)
          .split(RegExp('\\s+'))
          .where((part) => part.isNotEmpty)
          .orderedEquals(<String>['43', '44', '45']);
    }, skip: true);
  });

  test('level1 required', () {
    var environment = Environment(
      loader: MapLoader(<String, String>{
        'default': '{% block x required %}{# comment #}\n {% endblock %}',
        'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
      }),
    );

    environment.getTemplate('level1').render().equals('[1]');
  });

  test('level2 required', () {
    var environment = Environment(
      loader: MapLoader(<String, String>{
        'default': "{% block x required %}{% endblock %}",
        'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
        'level2': '{% extends "default" %}{% block x %}[2]{% endblock %}',
      }),
    );

    environment.getTemplate('level1').render().equals('[1]');
    environment.getTemplate('level2').render().equals('[2]');
  });

  test('level3 required', () {
    var environment = Environment(
      loader: MapLoader(<String, String>{
        'default': '{% block x required %}{% endblock %}',
        'level1': '{% extends "default" %}',
        'level2': '{% extends "level1" %}{% block x %}[2]{% endblock %}',
        'level3': '{% extends "level2" %}',
      }),
    );

    environment
        .getTemplate('level1')
        .renderThrows<TemplateSyntaxError>(matcher: (error) => error.message == 'required block \'x\' not found');
    environment.getTemplate('level2').render().equals('[2]');
    environment.getTemplate('level3').render().equals('[2]');
  });

  test('invalid required', () {
    var environment = Environment(
      loader: MapLoader(<String, String>{
        'default': '{% block x required %}data {# #}{% endblock %}',
        'default1': '{% block x required %}{% block y %}{% endblock %}  {% endblock %}',
        'default2': '{% block x required %}{% if true %}{% endif %}  {% endblock %}',
        "level1default": '{% extends "default" %}{%- block x %}CHILD{% endblock %}',
        "level1default2": '{% extends "default2" %}{%- block x %}CHILD{% endblock %}',
        "level1default3": '{% extends "default3" %}{%- block x %}CHILD{% endblock %}',
      }),
    );

    bool matcher(dynamic error) {
      return error.message == 'required block \'x\' not found';
    }

    environment
      ..getTemplate('level1default').renderThrows<TemplateSyntaxError>(matcher: matcher)
      ..getTemplate('level1default2').renderThrows<TemplateSyntaxError>(matcher: matcher)
      ..getTemplate('level1default3').renderThrows<TemplateSyntaxError>(matcher: matcher);
  });
}
