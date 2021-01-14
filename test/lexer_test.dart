import 'package:renderable/jinja.dart';
import 'package:renderable/src/reader.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('TokenReader', () {
    const testTokens = <Token>[Token(1, 'block_begin', ''), Token(2, 'block_end', '')];
    test('simple', () {
      final reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
    });

    test('simple', () {
      final reader = TokenReader(testTokens);
      final tokenTypes = [for (final token in reader.values) token.type];
      expect(tokenTypes, equals(['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    final environment = Environment();

    test('raw', () {
      final template = environment.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final template = environment.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      final environment = Environment(lStripBlocks: true, trimBlocks: true);
      final template = environment.fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.render({'baz': 'test'}), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final environment = Environment(blockBegin: '{%', blockEnd: '%}', variableBegin: r'${', variableEnd: '}');
      final template = environment.fromString(r'''{% for item in seq
            %}${{'foo': item} | string | upper}{% endfor %}''');
      expect(template.render({'seq': [0, 1, 2]}), equals('{FOO: 0}{FOO: 1}{FOO: 2}'), reason: template.nodes.toString());
    });

    test('comments', () {
      final environment = Environment(blockBegin: '<!--', blockEnd: '-->', variableBegin: '{', variableEnd: '}');
      final template = environment.fromString('''\
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(template.render({'seq': [0, 1, 2]}), equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      for (final char in ['\0', '\u2668', '\xe4', '\t', '\r', '\n']) {
        final template = environment.fromString('{{ ${represent(char)} }}');
        expect(template.render(), equals(char));
      }

      // TODO: waiting for a realization in the dart sdk
      // expect(environment.fromString('{{ "\N{HOT SPRINGS}" }}').render(), equals('\u2668'));
    });

    test('normalizing', () {
      for (final seq in ['\r', '\r\n', '\n']) {
        final environment = Environment(newLine: seq);
        final template = environment.fromString('1\n2\r\n3\n4\n');
        expect(template.render().replaceAll(seq, 'X'), equals('1X2X3X4'));
      }
    });
  });

  group('Environment.lStripBlocks', () {
    final environment = Environment();

    test('lstrip', () {
      final environment = Environment(lStripBlocks: true);
      final template = environment.fromString('    {% if true %}\n    {% endif %}');
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
          variableBegin: r'${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          /* '%', '##', */
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('    <% if true %>hello    <% endif %>');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: r'${',
          variableEnd: '}',
          commentBegin: '<%#',
          commentEnd: '%>',
          /* '%', '##', */
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString('    <%# if true %>hello    <%# endif %>');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip angle bracket', () {
      final environment = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        /* '%', '##', */
        lStripBlocks: true,
        trimBlocks: true,
      );
      final template = environment.fromString(r'''
    <%# regular comment %>
    <% for item in seq %>
${item} ## the rest of the stuff
   <% endfor %>''');
      expect(template.render({'seq': range(5)}), equals(range(5).map((int n) => '$n\n').join()));
    });

    test('lstrip angle bracket compact', () {
      final environment = Environment(
          blockBegin: '<%',
          blockEnd: '%>',
          variableBegin: r'${',
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
      expect(template.render({'seq': range(5)}), equals(range(5).map((int n) => '$n\n').join()));
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
      expect(template.render({'seq': range(5)}), equals('01234'));
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
      expect(template.render({'seq': range(5)}), equals(range(5).map<String>((int n) => '        $n\n').join()));
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
      expect(template.render({'seq': range(5)}), equals(range(5).map<String>((int n) => '        $n\n').join()));
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
      expect(template.render({'seq': range(5)}), equals(range(5).map<String>((int n) => '    $n\n').join()));
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
      expect(template.render({'seq': range(5)}), equals('01234'));
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
      expect(template.render({'seq': range(5)}), equals('    01234'));
    });

    test('comment syntax', () {
      final environment = Environment(
          blockBegin: '<!--',
          blockEnd: '-->',
          variableBegin: r'${',
          variableEnd: '}',
          commentBegin: '<!--#',
          commentEnd: '-->',
          lStripBlocks: true,
          trimBlocks: true);
      final template = environment.fromString(r'''<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(template.render({'seq': range(5)}), equals('01234'));
    });
  });
}
