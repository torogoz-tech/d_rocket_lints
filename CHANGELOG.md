# Changelog

All notable changes to `d_rocket_lints` are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com).

## [2.0.0] — 2026-06-22

### Breaking

- **Plugin host migration**: switched from the archived
  `custom_lint_builder 0.8.x` (max `analyzer 8.0.0`) to the
  official `analysis_server_plugin 0.3.x` from
  `tools.dart.dev`. `analyzer` is bumped from `^8.4.0` to
  `^10.0.1`. This is the minimum to be on the same
  analyzer major as `d_rocket_builder` 2.0.0.
- **SDK floor**: `sdk: ^3.9.0` (was `^3.4.0`).
- **Discovery**: the `analyzer.plugins: [d_rocket_lints]`
  block in `analysis_options.yaml` replaces the old
  `custom_lint:` block. The two are mutually exclusive.
- **Rule class names**: the rule classes moved into a
  `rules/` sub-namespace. If you were importing the
  top-level `linq_closure_lint.dart` or
  `n_plus_one_lint.dart` files (only relevant for plugin
  host testing), update the import.

### Added

- 2 active rules at GA:
  - `LinqClosureRule` — detects `dbSet.where_(b => b.x == 1)`
    style LINQ predicates that evaluate in-memory only
    and offers a `dart fix` suggestion to wrap the
    closure in `Expr.lambda(...)` for SQL translation.
  - `NPlusOneRule` — detects `for` loops over
    `dbSet.where_(...).toList()` that trigger an N+1
    navigation fetch (one query per row, instead of one
    `IN (...)` query).
- Golden test fixtures in `test/goldens/` for both
  rules (positive + negative cases).
- `dart fix` support for `LinqClosureRule`.

### Migration from 1.x

```yaml
# analysis_options.yaml — 1.x
analyzer:
  plugins:
    custom_lint:
    - package:d_rocket_lints
```

```yaml
# analysis_options.yaml — 2.0
analyzer:
  plugins:
    d_rocket_lints:
```

### Removed (from 1.x)

- The `lint_rule_test.dart` `dart fix` golden file for
  `LinqClosureRule` (the rule was promoted out of beta
  and the fix file was renamed for clarity).
- `pub_workspace.dart` test helper (was specific to
  the `custom_lint_builder` host and is no longer
  applicable).
