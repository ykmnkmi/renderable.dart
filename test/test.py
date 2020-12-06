from jinja2 import Template

source = '*{{ name if true else none~0~[1]~name }}*'
tmpl = Template(source)
print(tmpl.render(name='Name'))
