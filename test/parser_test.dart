import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('Parser', () {
    test('php syntax', () {
      final environment = Environment(
          blockBegin: '<?',
          blockEnd: '?>',
          variableBegin: '<?=',
          variableEnd: '?>',
          commentBegin: '<!--',
          commentEnd: '-->');
      final template = environment.fromString('''<!-- I'm a comment, I'm not interesting --><? for item in seq -?>
    <?= item ?>
<?- endfor ?>''');
      expect(template.render({'seq': range(5)}), equals('01234'));
    });

    test('erb syntax', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '<%=',
          variableEnd: '%>',
          commentBegin: '<%#',
          commentEnd: '%>');
      final template = environment.fromString('''<%# I'm a comment, I'm not interesting %><% for item in seq -%>
    <%= item %>
<%- endfor %>''');
      expect(template.render({'seq': range(5)}), equals('01234'));
    });

    test('comment syntax', () {
      final environment = Environment(
          blockBegin: '<!--',
          blockEnd: '-->',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<!--#',
          commentEnd: '-->');
      final template = environment.fromString(r'''<!--# I'm a comment, I'm not interesting --><!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(template.render({'seq': range(5)}), equals('01234'));
    });

    test('balancing', () {
      final environment = Environment();
      final template = environment.fromString('''{{{'foo':'bar'}.foo}}''');
      expect(template.render(), equals('bar'));
    });

    test('start comment', () {
      final environment = Environment();
      final template = environment.fromString('''{# foo comment
and bar comment #}
{% macro blub() %}foo{% endmacro %}
{{ blub() }}''');
      expect(template.render().trim(), equals('foor'));
    }, skip: /* TODO: remove after macro */ true);

    test('line syntax', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%');
      final template = environment.fromString(r'''<%# regular comment %>
% for item in seq:
    ${item} ## the rest of the stuff
% endfor''');
      final sequence = range(5).toList();
      final numbers = template
          .render({'seq': sequence})
          .split(RegExp('\\s+'))
          .map((string) => string.trim())
          .where((string) => string.isNotEmpty)
          .map((string) => int.parse(string.trim()))
          .toList();
      expect(numbers, equals(sequence));
    });

    test('line syntax priority', () {
      var environment = Environment(
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '/*',
          commentEnd: '*/',
          lineCommentPrefix: '#',
          lineStatementPrefix: '##');
      var template = environment.fromString(r'''/* ignore me.
   I'm a multiline comment */
## for item in seq:
* ${item}          # this is just extra stuff
## endfor''');
      expect(
          template.render({
            'seq': [1, 2]
          }).trim(),
          equals('* 1\n* 2'));
      environment = Environment(
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '/*',
          commentEnd: '*/',
          lineCommentPrefix: '##',
          lineStatementPrefix: '#');
      template = environment.fromString(r'''/* ignore me.
   I'm a multiline comment */
# for item in seq:
* ${item}          ## this is just extra stuff
    ## extra stuff i just want to ignore
# endfor''');
      expect(
          template.render({
            'seq': [1, 2]
          }).trim(),
          equals('* 1\n\n* 2'));
    });

    test('error messages', () {
      void assertError(String source, String expekted) {
        expect(() => Template(source),
            throwsA(predicate((error) => error is TemplateSyntaxError && error.message == expekted)));
      }

      assertError(
        '{% for item in seq %}...{% endif %}',
        'Encountered unknown tag \'endif\'. Jinja was looking '
            'for the following tags: \'endfor\' or \'else\'. The '
            'innermost block that needs to be closed is \'for\'.',
      );
      assertError(
        '{% if foo %}{% for item in seq %}...{% endfor %}{% endfor %}',
        'Encountered unknown tag \'endfor\'. Jinja was looking for '
            'the following tags: \'elif\' or \'else\' or \'endif\'. The '
            'innermost block that needs to be closed is \'if\'.',
      );
      assertError(
        '{% if foo %}',
        'Unexpected end of template. Jinja was looking for the '
            'following tags: \'elif\' or \'else\' or \'endif\'. The '
            'innermost block that needs to be closed is \'if\'.',
      );
      assertError(
        '{% for item in seq %}',
        'Unexpected end of template. Jinja was looking for the '
            'following tags: \'endfor\' or \'else\'. The innermost block '
            'that needs to be closed is \'for\'.',
      );
      assertError(
        '{% block foo-bar-baz %}',
        'use an underscore instead',
      );
      assertError('{% unknown_tag %}', 'Encountered unknown tag \'unknown_tag\'.');
    });
  });
}
