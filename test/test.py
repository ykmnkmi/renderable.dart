from jinja2 import Template

source = '*{{ 2 * "a" }}*'
tmpl = Template(source)
print(tmpl.render(name='Name'))
