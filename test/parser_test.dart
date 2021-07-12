import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

void main() {
  group('Parser', () {
    test('php syntax', () {
      final env = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: '<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
      );

      final tmpl = env.fromString('<!-- I\'m a comment -->'
          '<? for item in seq -?>\n    <?= item ?>\n<?- endfor ?>');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('erb syntax', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '<%=',
        variableEnd: '%>',
        commentBegin: '<%#',
        commentEnd: '%>',
      );

      final tmpl = env.fromString('<%# I\'m a comment %>'
          '<% for item in seq -%>\n    <%= item %><%- endfor %>');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('comment syntax', () {
      final env = Environment(
        blockBegin: '<!--',
        blockEnd: '-->',
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '<!--#',
        commentEnd: '-->',
      );

      final tmpl = env.fromString('<!--# I\'m a comment -->'
          '<!-- for item in seq --->    \${item}<!--- endfor -->');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('balancing', () {
      final tmpl = env.fromString('''{{{'foo':'bar'}.foo}}''');
      expect(tmpl.render(), equals('bar'));
    });

    // TODO: after macro: enable test
    // test('start comment', () {
    //   final tmpl = env.fromString('{# foo comment\nand bar comment #}'
    //       '{% macro blub() %}foo{% endmacro %}\n{{ blub() }}');
    //   expect(tmpl.render().trim(), equals('foor'));
    // });

    test('line syntax', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
      );

      final sequence = range(5).toList();
      final tmpl = env.fromString('<%# regular comment %>\n% for item in seq:\n'
          '    \${item} ## the rest of the stuff\n% endfor');
      final result = tmpl
          .render({'seq': sequence})
          .split(RegExp('\\s+'))
          .map<String>((string) => string.trim())
          .where((string) => string.isNotEmpty)
          .map<int>((string) => int.parse(string.trim()))
          .toList();
      expect(result, equals(sequence));
    });

    test('line syntax priority', () {
      final seq = <int>[1, 2];

      var env = Environment(
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '/*',
        commentEnd: '*/',
        lineCommentPrefix: '#',
        lineStatementPrefix: '##',
      );

      var tmpl =
          env.fromString('/* ignore me.\n   I\'m a multiline comment */\n'
              '## for item in seq:\n* \${item}          '
              '# this is just extra stuff\n## endfor\n');
      expect(tmpl.render({'seq': seq}).trim(), equals('* 1\n* 2'));

      env = Environment(
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '/*',
        commentEnd: '*/',
        lineCommentPrefix: '##',
        lineStatementPrefix: '#',
      );

      tmpl = env.fromString('/* ignore me.\n   I\'m a multiline comment */\n'
          '# for item in seq:\n* \${item}          '
          '## this is just extra stuff\n    '
          '## extra stuff i just want to ignore\n# endfor');
      expect(tmpl.render({'seq': seq}).trim(), equals('* 1\n\n* 2'));
    });

    test('error messages', () {
      void assertError(String source, String expekted) {
        void callback() {
          env.fromString(source);
        }

        bool matcher(TemplateSyntaxError error) {
          return error.message == expekted;
        }

        expect(callback, throwsA(predicate<TemplateSyntaxError>(matcher)));
      }

      assertError(
          '{% for item in seq %}...{% endif %}',
          'Encountered unknown tag \'endif\'. Jinja was looking '
              'for the following tags: \'endfor\' or \'else\'. The '
              'innermost block that needs to be closed is \'for\'.');
      assertError(
          '{% if foo %}{% for item in seq %}...{% endfor %}{% endfor %}',
          'Encountered unknown tag \'endfor\'. Jinja was looking for '
              'the following tags: \'elif\' or \'else\' or \'endif\'. The '
              'innermost block that needs to be closed is \'if\'.');
      assertError(
          '{% if foo %}',
          'Unexpected end of template. Jinja was looking for the '
              'following tags: \'elif\' or \'else\' or \'endif\'. The '
              'innermost block that needs to be closed is \'if\'.');
      assertError(
          '{% for item in seq %}',
          'Unexpected end of template. Jinja was looking for the '
              'following tags: \'endfor\' or \'else\'. The innermost block '
              'that needs to be closed is \'for\'.');
      assertError('{% block foo-bar-baz %}', 'use an underscore instead');
      assertError(
          '{% unknown_tag %}', 'Encountered unknown tag \'unknown_tag\'.');
    });
  });
}
