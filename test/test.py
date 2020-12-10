from jinja2 import Template

source = '*{{ list[0:5:1] }}*'
tmpl = Template(source)
print(tmpl.render(list=[1, 2]))
