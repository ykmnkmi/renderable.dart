#!/usr/bin/python3

import sys
from jinja2 import Environment

print(Environment(extensions=['jinja2.ext.do']).compile(''.join(sys.argv[1:]), raw=True))
