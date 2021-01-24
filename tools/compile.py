import sys

if __name__ == '__main__':
  if len(sys.argv) == 1: sys.exit(1)
  
  from jinja2 import Environment
  print(Environment().compile(''.join(sys.argv[1:]), raw=True))
