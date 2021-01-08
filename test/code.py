from __future__ import division, generator_stop
from jinja2.runtime import LoopContext, TemplateReference, Macro, Markup, TemplateRuntimeError, missing, concat, escape, markup_join, unicode_join, to_string, identity, TemplateNotFound, Namespace
name = None

def root(context, missing=missing, environment=environment):
    resolve = context.resolve_or_missing
    undefined = environment.undefined
    if 0: yield None
    l_0_foo = missing
    pass
    l_1_test = resolve('test')
    t_1 = []
    pass
    t_1.extend(('<em>', escape((undefined(name='test') if l_1_test is missing else l_1_test)), '</em>'))
    l_0_foo = (Markup if context.eval_ctx.autoescape else identity)(concat(t_1))
    context.vars['foo'] = l_0_foo
    context.exported_vars.add('foo')
    l_1_test = missing
    yield 'foo: '
    yield escape((undefined(name='foo') if l_0_foo is missing else l_0_foo))

blocks = {}
debug_info = '1=16'