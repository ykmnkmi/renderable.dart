from jinja2 import Template

source = '*{{ 1 < 2 < 0 == 0 }}*'
tmpl = Template(source)
print(tmpl.render(name=5))
