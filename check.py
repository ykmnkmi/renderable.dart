from jinja2 import Template

template = Template('{{ "a" }}|{{ ["a"] }}|{{ "a", }}!')

print(template.render(a='jhon'))
