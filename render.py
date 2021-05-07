#!/usr/bin/python3

import sys
from jinja2 import Environment

env = Environment()

print(env.from_string(''.join(sys.stdin)).render())
