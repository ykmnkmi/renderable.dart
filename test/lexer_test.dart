import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/src/exceptions.dart';
import 'package:renderable/src/reader.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('TokenReader', () {
    final testTokens = [Token(1, 'block_begin', ''), Token(2, 'block_end', '')];

    test('simple', () {
      final reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
    });

    test('iter', () {
      final reader = TokenReader(testTokens);
      final tokenTypes = [for (final token in reader.values) token.type];
      expect(tokenTypes, equals(['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    test('raw', () {
      final environment = Environment();
      final template = environment.fromString('{% raw %}foo{% endraw %}|{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final environment = Environment();
      final template = environment.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(render(template, baz: 'test'), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final environment = Environment(blockBegin: '{%', blockEnd: '%}', variableBegin: '\${', variableEnd: '}');
      final template = environment.fromString(r'''{% for item in seq
            %}${{'foo': item}|upper}{% endfor %}''');
      expect(render(template, seq: [0, 1, 2]), equals('{FOO: 0}{FOO: 1}{FOO: 2}'));
    });

    test('comments', () {
      final environment = Environment(blockBegin: '<!--', blockEnd: '-->', variableBegin: '{', variableEnd: '}');
      final template = environment.fromString('''
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(render(template, seq: [0, 1, 2]), equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      final environment = Environment();
      Template template;

      for (final char in ['\0', '\u2668', '\xe4', '\t', '\r', '\n']) {
        template = environment.fromString('{{ ${represent(char)} }}');
        expect(template.render(), equals(char));
      }

      // not supported
      // template = environment.fromString('{{ "\N{HOT SPRINGS}" }}');
      // expect(template.render(), equals('\u2668'));
    });

    // not supported
    // test('bytefallback', () {
    //   final environment = Environment();
    //   final template = environment.fromString('{{ \'foo\'|pprint }}|{{ \'bär\'|pprint }}');
    //   expect(template.render(), equals(pformat('foo') + '|' + pformat('bär')));
    // });

    test('operators', () {
      final environment = Environment();
      operators.forEach((test, expekt) {
        if ('([{}])'.contains(test)) {
          return;
        }

        final tokens = Lexer(environment).tokenize('{{ $test }}');
        expect(tokens[1], equals(predicate<Token>((token) => token.test(expekt))));
      });
    });

    test('normalizing', () {
      for (final newLine in ['\r', '\r\n', '\n']) {
        final environment = Environment(newLine: newLine);
        final template = environment.fromString('1\n2\r\n3\n4\n');
        expect(template.render().replaceAll(newLine, 'X'), equals('1X2X3X4'));
      }
    });

    test('trailing newline', () {
      final matches = <String, Map<bool, String>>{
        '': {},
        'no\nnewline': {},
        'with\nnewline\n': {false: 'with\nnewline'},
        'with\nseveral\n\n\n': {false: 'with\nseveral\n\n'},
      };

      for (final keep in [true, false]) {
        final environment = Environment(keepTrailingNewLine: keep);
        matches.forEach((source, expekted) {
          final template = environment.fromString(source);
          final expekt = expekted[keep] ?? source;
          final result = template.render();
          expect(result, equals(expekt));
        });
      }
    });

    test('name', () {
      final matches = <String, bool>{
        'foo': true,
        '_': true,
        '1a': false, // invalid ascii start
        'a-': false, // invalid ascii continue
      };

      final environment = Environment();
      matches.forEach((name, valid) {
        if (valid) {
          expect(environment.fromString('{{ $name }}'), isA<Template>());
        } else {
          expect(() => environment.fromString('{{ $name }}'), throwsA(isA<TemplateSyntaxError>()));
        }
      });
    });

    test('lineno with strip', () {
      final environment = Environment();
      final tokens = Lexer(environment).tokenize('''<html>
    <body>
    {%- block content -%}
        <hr>
        {{ item }}
    {% endblock %}
    </body>
</html>''');
      for (final token in tokens) {
        if (token.test('name', 'item')) {
          expect(token.line, equals(5));
        }
      }
    });
  });

  group('Parser', () {
    test('php syntax', () {
      final environment = Environment(blockBegin: '<?', blockEnd: '?>', variableBegin: '<?=', variableEnd: '?>', commentBegin: '<!--', commentEnd: '-->');
      final template = environment.fromString('''<!-- I'm a comment, I'm not interesting --><? for item in seq -?>
    <?= item ?>
<?- endfor ?>''');
      expect(render(template, seq: range(5)), equals('01234'));
    });

    test('erb syntax', () {
      final environment = Environment(blockBegin: '<%', blockEnd: '%>', variableBegin: '<%=', variableEnd: '%>', commentBegin: '<%#', commentEnd: '%>');
      final template = environment.fromString('''<%# I'm a comment, I'm not interesting %><% for item in seq -%>
    <%= item %>
<%- endfor %>''');
      expect(render(template, seq: range(5)), equals('01234'));
    });

    test('comment syntax', () {
      final environment = Environment(blockBegin: '<!--', blockEnd: '-->', variableBegin: '\${', variableEnd: '}', commentBegin: '<!--#', commentEnd: '-->');
      final template = environment.fromString(r'''<!--# I'm a comment, I'm not interesting --><!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(render(template, seq: range(5)), equals('01234'));
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
    });

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
      final numbers = (render(template, seq: sequence) as String)
          .split(RegExp('\\s+'))
          .map((String string) => string.trim())
          .where((String string) => string.isNotEmpty)
          .map((String string) => int.parse(string.trim()))
          .toList();
      expect(numbers, equals(sequence));
    });

    test('line syntax priority', () {
      var environment =
          Environment(variableBegin: '\${', variableEnd: '}', commentBegin: '/*', commentEnd: '*/', lineCommentPrefix: '#', lineStatementPrefix: '##');
      var template = environment.fromString(r'''/* ignore me.
   I'm a multiline comment */
## for item in seq:
* ${item}          # this is just extra stuff
## endfor''');
      expect((render(template, seq: [1, 2]) as String).trim(), equals('* 1\n* 2'));

      environment =
          Environment(variableBegin: '\${', variableEnd: '}', commentBegin: '/*', commentEnd: '*/', lineCommentPrefix: '##', lineStatementPrefix: '#');
      template = environment.fromString(r'''/* ignore me.
   I'm a multiline comment */
# for item in seq:
* ${item}          ## this is just extra stuff
    ## extra stuff i just want to ignore
# endfor''');
      expect((render(template, seq: [1, 2]) as String).trim(), equals('* 1\n\n* 2'));
    });

    test('error messages', () {
      void assertError(String source, String expekted) {
        expect(() => Template(source), throwsA(predicate((error) => error is TemplateSyntaxError && error.message == expekted)));
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
        'Block names in Jinja have to be valid Python identifiers '
            'and may not contain hyphens, use an underscore instead.',
      );
      assertError('{% unknown_tag %}', 'Encountered unknown tag \'unknown_tag\'.');
    });
  });

  group('Syntax', () {
    test('call', () {
      final environment = Environment();
      environment.globals['foo'] = (dynamic a, dynamic b, {dynamic c, dynamic e, dynamic g}) => a + b + c + e + g;
      final template = environment.fromString('{{ foo(\'a\', c=\'d\', e=\'f\', *[\'b\'], **{\'g\': \'h\'}) }}');
      expect(template.render(), equals('abdfh'));
    });

    // TODO: add https://github.com/pallets/jinja/blob/81911fdb3065f1156d84ca52ee3a257c229ebc59/tests/test_lexnparse.py#L325
  });

  group('LStripBlocks', () {
    test('lstrip', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {% if True %}\n    {% endif %}');
      expect(template.render(), equals('\n'));
    });

    test('lstrip trim', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals(''));
    });

    test('no lstrip', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      final environment = Environment();
      var template = environment.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));
      template = environment.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('lstrip endline', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    hello{% if true %}\n    goodbye{% endif %}');
      expect(template.render(), equals('    hello\n    goodbye'));
    });

    test('lstrip inline', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {% if true %}hello    {% endif %}');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip nested', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {% if true %}a {% if true %}b {% endif %}c {% endif %}');
      expect(template.render(), equals('a b c '));
    });

    test('lstrip left chars', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('''    abc {% if true %}
        hello{% endif %}''');
      expect(template.render(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(template.render(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('\n\n\n{% set hello = 1 %}');
      expect(template.render(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('''    {# if true #}
hello
    {#endif#}''');
      expect(template.render(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('    <% if true %>hello    <% endif %>');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('    <%# if true %>hello    <%# endif %>');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip angle bracket', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString(r'''
    <%# regular comment %>
    <% for item in seq %>
${item} ## the rest of the stuff
   <% endfor %>''');
      expect(render(template, seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
    });

    test('lstrip angle bracket compact', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString(r'''    <%#regular comment%>
    <%for item in seq%>
${item} ## the rest of the stuff
   <%endfor%>''');
      expect(render(template, seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
    });

    // TODO: add https://github.com/pallets/jinja/blob/81911fdb3065f1156d84ca52ee3a257c229ebc59/tests/test_lexnparse.py#L716

    test('php syntax with manual', () {
      final environment = Environment(
          blockBegin: '<?',
          blockEnd: '?>',
          variableBegin: '<?=',
          variableEnd: '?>',
          commentBegin: '<!--',
          commentEnd: '-->',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(render(template, seq: range(5)), equals('01234'));
    });

    test('php syntax', () {
      final environment = Environment(
          blockBegin: '<?',
          blockEnd: '?>',
          variableBegin: '<?=',
          variableEnd: '?>',
          commentBegin: '<!--',
          commentEnd: '-->',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(render(template, seq: range(5)), equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('php syntax compact', () {
      final environment = Environment(
          blockBegin: '<?',
          blockEnd: '?>',
          variableBegin: '<?=',
          variableEnd: '?>',
          commentBegin: '<!--',
          commentEnd: '-->',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<!-- I'm a comment, I'm not interesting -->
    <?for item in seq?>
        <?=item?>
    <?endfor?>''');
      expect(render(template, seq: range(5)), equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('erb syntax', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '<%=',
          variableEnd: '%>',
          commentBegin: '<%#',
          commentEnd: '%>',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
''');
      expect(render(template, seq: range(5)), equals(range(5).map<String>((int n) => '    $n\n').join()));
    });

    test('erb syntax with manual', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '<%=',
          variableEnd: '%>',
          commentBegin: '<%#',
          commentEnd: '%>',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(render(template, seq: range(5)), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '<%=',
          variableEnd: '%>',
          commentBegin: '<%#',
          commentEnd: '%>',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('''<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(render(template, seq: range(5)), equals('    01234'));
    });

    test('comment syntax', () {
      final environment = Environment(
          blockBegin: '<!--',
          blockEnd: '-->',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<!--#',
          commentEnd: '-->',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString(r'''<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(render(template, seq: range(5)), equals('01234'));
    });
  });

  group('TrimBlocks', () {
    test('trim', () {
      final environment = Environment(trimBlocks: true);
      final template = environment.fromString('    {% if True %}\n    {% endif %}');
      expect(template.render(), equals('        '));
    });

    test('no trim', () {
      final environment = Environment(trimBlocks: true);
      final template = environment.fromString('    {% if True +%}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('no trim outer', () {
      final environment = Environment(trimBlocks: true);
      final template = environment.fromString('{% if True %}X{% endif +%}\nmore things');
      expect(template.render(), equals('X\nmore things'));
    });

    test('lstrip no trim', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {% if True +%}\n    {% endif %}');
      expect(template.render(), equals('\n'));
    });

    test('trim blocks false with no trim', () {
      final environment = Environment();
      var template = environment.fromString('    {% if True %}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));
      template = environment.fromString('    {% if True +%}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));

      template = environment.fromString('    {# comment #}\n    ');
      expect(template.render(), equals('    \n    '));
      template = environment.fromString('    {# comment +#}\n    ');
      expect(template.render(), equals('    \n    '));

      template = environment.fromString('    {% raw %}{% endraw %}\n    ');
      expect(template.render(), equals('    \n    '));
      template = environment.fromString('    {% raw %}{% endraw +%}\n    ');
      expect(template.render(), equals('    \n    '));
    });

    test('trim nested', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {% if True %}\na {% if True %}\nb {% endif %}\nc {% endif %}');
      expect(template.render(), equals('a b c '));
    });

    test('no trim nested', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {% if True +%}\na {% if True +%}\nb {% endif +%}\nc {% endif %}');
      expect(template.render(), equals('\na \nb \nc '));
    });

    test('comment trim', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {# comment #}\n\n  ');
      expect(template.render(), equals('\n  '));
    });

    test('comment no trim', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('    {# comment +#}\n\n  ');
      expect(template.render(), equals('\n\n  '));
    });

    test('multiple comment trim lstrip', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('   {# comment #}\n\n{# comment2 #}\n   \n{# comment3 #}\n\n ');
      expect(template.render(), equals('\n   \n\n '));
    });

    test('multiple comment no trim lstrip', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('   {# comment +#}\n\n{# comment2 +#}\n   \n{# comment3 +#}\n\n ');
      expect(template.render(), equals('\n\n\n   \n\n\n '));
    });

    test('raw trim lstrip', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('{{x}}{% raw %}\n\n    {% endraw %}\n\n{{ y }}');
      expect(render(template, x: 1, y: 2), equals('1\n\n\n2'));
    });

    test('raw no trim lstrip', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('{{x}}{% raw %}\n\n      {% endraw +%}\n\n{{ y }}');
      expect(render(template, x: 1, y: 2), equals('1\n\n\n\n2'));
    });

    test('no trim angle bracket', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: '\${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          lStripBlocks: true,
          trimBlocks: true);
      var template = environment.fromString('    <% if True +%>\n\n    <% endif %>');
      expect(template.render(), equals('\n\n'));
      template = environment.fromString('    <%# comment +%>\n\n   ');
      expect(template.render(), equals('\n\n   '));
    });

    test('no trim php syntax', () {
      final environment =
          Environment(blockBegin: '<?', blockEnd: '?>', variableBegin: r'<?=', variableEnd: '?>', commentBegin: '<!--', commentEnd: '-->', trimBlocks: true);
      var template = environment.fromString('    <? if True +?>\n\n    <? endif ?>');
      expect(template.render(), equals('    \n\n    '));
      template = environment.fromString('    <!-- comment +-->\n\n    ');
      expect(template.render(), equals('    \n\n    '));
    });
  });
}
