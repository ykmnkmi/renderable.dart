import 'package:renderable/runtime.dart';

import 'core.dart';

void main() {
  group('Escape', () {
    test('empty', () {
      escape('').equals('');
    });

    test('ascii', () {
      escape(r'''abcd&><'"efgh''').equals('abcd&amp;&gt;&lt;&#39;&#34;efgh');
      escape(r'''&><'"efgh''').equals('&amp;&gt;&lt;&#39;&#34;efgh');
      escape(r'''abcd&><'"''').equals('abcd&amp;&gt;&lt;&#39;&#34;');
    });

    test('2 byte', () {
      escape(r'''こんにちは&><'"こんばんは''').equals('こんにちは&amp;&gt;&lt;&#39;&#34;こんばんは');
      escape(r'''&><'"こんばんは''').equals('&amp;&gt;&lt;&#39;&#34;こんばんは');
      escape(r'''こんにちは&><'"''').equals('こんにちは&amp;&gt;&lt;&#39;&#34;');
    });

    test('4 byte', () {
      escape(r'''\U0001F363\U0001F362&><'"\U0001F37A xyz''')
          .equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz');
      escape(r'''&><'"\U0001F37A xyz''').equals(r'&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz');
      escape(r'''\U0001F363\U0001F362&><'"''').equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;');
    });
  });
}
