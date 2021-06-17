#!/usr/bin/python3

import sys
from jinja2 import Environment

print(Environment().from_string(''.join(sys.argv[1:])).render())
