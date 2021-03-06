Renderable.dart
===============

[Jinja.dart](https://github.com/ykmnkmi/jinja.dart) next stable version, will be merged to jinja.dart repo.
After merging this package will be simplified to object based context and divided to annotations and generator.

Differences:
- no context and environment function decorators, use `context`/`ctx` or `environment`/`env` variables: `{{ function(ctx/env, ...) }}` and
  `Environment(contextFilters: {...}, environmentFilters: {...})` parameters for filters.
- `inlcude` and `extends` accepts only single existing template.
- ... working

## Status:
### ToDo:
- Environment
  - constructor
    - ~~extensions~~
    - ~~selectAutoescape~~
  - ~~addExtension~~
  - ~~compileExpression~~
  - ~~shared~~
- Template
  - ~~generate~~
  - ~~stream~~
- Loaders
  - ~~PackageLoader~~
  - ...
- ... working

### Templates:
- Variables `[a-zA-Z$_][a-zA-Z0-9$_]*`
- Filters
- Tests
- Comments
- Whitespace Control
- Escaping
- Line Statements
  - Comments
  - Blocks
- Template Inheritance
  - Base Template
  - Child Template
  - Super Blocks
  - Nesting extends
  - Named Block End-Tags
  - Block Nesting and Scope
- HTML Escaping
  - Working with Manual Escaping
  - Working with Automatic Escaping
- List of Control Structures
  - For
  - If
  - ~~Macros~~
  - ~~Call~~
  - ~~Filters~~
  - Assignments
  - Block Assignments
  - Extends
  - Blocks
  - Include
  - ~~Import~~
- Import Context Behavior
- Expressions
  - Literals: null (none), true (True), false (False), 1_000, 1.1e3, 'sq', "dq", (1,), \[2\], {'k': 'v'}
  - Math
  - Comparisons
  - Logic
  - Other Operators
  - If Expression
  - Dart Methods
- List of Builtin Filters
  - abs
  - attr
  - batch
  - capitalize
  - center
  - default, d
  - escape, e
  - filesizeformat
  - first
  - float
  - forceescape
  - int
  - join
  - last
  - length, count
  - list
  - lower
  - pprint: bool, num, String, List, Map, Set
  - random
  - replace
  - reverse
  - safe
  - string
  - sum
  - trim
  - upper
  - wordwrap
- List of Builtin Tests
  - boolean
  - callable
  - defined
  - divisibleby
  - eq, equalto, ==
  - escaped
  - even
  - false
  - float
  - ge, >=
  - gt, greaterthan, >
  - in
  - integer
  - iterable
  - le, <=
  - lower
  - lt, lessthan, <
  - mapping
  - ne, !=
  - none
  - number
  - odd
  - sameas
  - sequence
  - string
  - true
  - undefined
  - upper
- List of Global Functions
  - list
  - namespace
  - range
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Extensions
  - With Statement
  - ~~i18n~~
  - ~~Expression Statement~~
  - ~~Loop Controls~~
  - ~~Debug Statement~~
- Autoescape Overrides