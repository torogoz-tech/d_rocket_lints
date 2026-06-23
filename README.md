# d_rocket_lints

Analyzer plugin rules for the
[d_rocket 2.0](https://pub.dev/packages/d_rocket) framework.

Catches LINQ closures that would silently run in-memory
instead of being translated to SQL, and N+1 navigation
fetches in loops.

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  d_rocket_lints: ^2.0.0
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    d_rocket_lints:
```

## Rules

| Rule | Detects | Fix |
|---|---|---|
| `LinqClosureRule` | LINQ predicates like `dbSet.where_(b => b.x == 1)` that evaluate **in-memory only** (silent correctness footgun — works locally, returns wrong data against SQL Server / Postgres / etc.) | Wrap the closure in `Expr.lambda(...)` so the provider can translate it to SQL. `dart fix` applies the change automatically. |
| `NPlusOneRule` | `for (final r in dbSet.where_(...))` followed by a navigation access (`r.user`) that triggers a per-row fetch. | Use `include_<Target>()` (the codegen helper) to do a single `IN (...)` query. |

## Disabling a rule

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    d_rocket_lints:
      rules:
        LinqClosureRule: false
```

## Severity

Both rules default to `warning` in the plugin. The dev
can promote them to `error` in their
`analysis_options.yaml`:

```yaml
analyzer:
  errors:
    linq_closure_rule: error
    n_plus_one_rule: error
```

## Tests

14 tests across 5 files. Coverage is golden-file based
(uses `package:analyzer`'s test utilities).

```bash
dart test
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Torogoz Tech.
