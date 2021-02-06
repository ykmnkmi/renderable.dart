import 'package:renderable/ast.dart';
import 'package:renderable/jinja.dart';
import 'package:renderable/utils.dart';
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
      expect(template.render(<String, Object>{'baz': 'test'}), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final environment = Environment(blockBegin: '{%', blockEnd: '%}', variableBegin: '\${', variableEnd: '}');
      final template = environment.fromString(r'''{% for item in seq
            %}${{'foo': item} | string | upper}{% endfor %}''');
      expect(
        template.render(<String, Object>{
          'seq': <int>[0, 1, 2]
        }),
        equals('{FOO: 0}{FOO: 1}{FOO: 2}'),
      );
    });

    test('comments', () {
      final environment = Environment(blockBegin: '<!--', blockEnd: '-->', variableBegin: '{', variableEnd: '}');
      final template = environment.fromString('''
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(
        template.render(<String, Object>{
          'seq': <int>[0, 1, 2]
        }),
        equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'),
      );
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals(range(5).map((int n) => '$n\n').join()));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals(range(5).map((int n) => '$n\n').join()));
    });

    test('lstrip blocks outside with new line', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('(\na=1 b=2 \n  )'),
      );
    });

    test('lstrip trim blocks outside with new line', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('(\na=1 b=2   )'),
      );
    });

    test('lstrip blocks inside with new line', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('  (\na=1 b=2 \n)'),
      );
    });

    test('lstrip trim blocks inside with new line', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('  (a=1 b=2 )'),
      );
    });

    test('lstrip blocks without new line', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('   a=1 b=2   '),
      );
    });

    test('lstrip trim blocks without new line', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('   a=1 b=2   '),
      );
    });

    test('lstrip blocks consume after without new line', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('  {% if kvs -%}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {% endif -%}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('a=1 b=2 '),
      );
    });

    test('lstrip trim blocks consume before without new line', () {
      final environment = Environment();
      final template = environment.fromString('  {%- if kvs %}'
          '   {%- for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {%- endif %}');
      expect(
        template.render(<String, Object>{
          'kvs': <List<Object>>[
            <Object>['a', 1],
            <Object>['b', 2]
          ]
        }),
        equals('a=1 b=2 '),
      );
    });

    test('lstrip trim blocks comment', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString(' {# 1 space #}\n  {# 2 spaces #}    {# 4 spaces #}');
      expect(template.render(), equals(' ' * 4));
    });

    test('lstrip trim blocks raw', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('{{x}}\n{%- raw %} {% endraw -%}\n{{ y }}');
      expect(template.render(<String, Object>{'x': 1, 'y': 2}), equals('1 2'));
    });

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
      expect(template.render(<String, Object>{'seq': range(5)}), equals('01234'));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals(range(5).map<String>((int n) => '        $n\n').join()));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals(range(5).map<String>((int n) => '        $n\n').join()));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals(range(5).map<String>((int n) => '    $n\n').join()));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals('01234'));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals('    01234'));
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
      expect(template.render(<String, Object>{'seq': range(5)}), equals('01234'));
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
      expect(template.render(<String, Object>{'x': 1, 'y': 2}), equals('1\n\n\n2'));
    });

    test('raw no trim lstrip', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('{{x}}{% raw %}\n\n      {% endraw +%}\n\n{{ y }}');
      expect(template.render(<String, Object>{'x': 1, 'y': 2}), equals('1\n\n\n\n2'));
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
