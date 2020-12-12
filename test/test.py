from jinja2 import Environment
from jinja2.lexer import Lexer

source = '*{{{1: 2}}}*'
environment = Environment()
lexer = Lexer(environment)

for token in lexer.tokenize(source):
  print(token)

template = environment.from_string(source)
print(template.render(name=5))
