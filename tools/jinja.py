import sys

if __name__ == '__main__':
  if len(sys.argv) < 3: sys.exit(1)
  
  from jinja2 import Environment

  if sys.argv[1] == 'compile':
    print(Environment().compile(sys.argv[2], raw=True))
  elif sys.argv[1] == 'render':
    if len(sys.argv) == 3:
      print(Environment().from_string(sys.argv[2]).render())
    else:
      print(Environment().from_string(sys.argv[2]).render(eval(sys.argv[3])))
