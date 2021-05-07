#!/usr/bin/python3

import sys
from jinja2 import Environment

env = Environment(extensions=['jinja2.ext.do'])

print(env.compile(''.join(sys.stdin), raw=True))
