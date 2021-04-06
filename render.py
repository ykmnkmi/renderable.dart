#!/usr/bin/python3

import sys
from jinja2 import Environment

env = Environment()

print(env.from_string(sys.argv[1]).render())
