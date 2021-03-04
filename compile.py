#!/usr/bin/python3

import sys
from jinja2 import Environment

env = Environment()

print(env.compile(sys.argv[1], raw=True))
