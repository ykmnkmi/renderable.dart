#!/usr/bin/python3

import sys
from jinja2 import DictLoader, Environment

env = Environment(
    loader=DictLoader(
        {
            "layout.html": """
    {% block useless %}{% endblock %}
    """,
            "index.html": """
    {%- extends 'layout.html' %}
    {% from 'helpers.html' import foo with context %}
    {% block useless %}
        {% for x in [1, 2, 3] %}
            {% block testing scoped %}
                {{ foo(x) }}
            {% endblock %}
        {% endfor %}
    {% endblock %}
    """,
            "helpers.html": """
    {% macro foo(x) %}{{ the_foo + x }}{% endmacro %}
    """,
        }
    )
)
print(env.get_template("index.html").render(the_foo=42).split())
