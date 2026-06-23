# d_rocket_lints

<p align="center">
  <img src="assets/banner.png" alt="d_rocket_lints banner" width="100%">
</p>

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
    - d_rocket_lints
```

## Rules

The two rules are exposed by their diagnostic code
(`analysis_server_plugin` convention):

| Diagnostic code | Detects | Fix |
|---|---|---|
| `d_rocket_untranslated_closure_linq` | LINQ predicates like `dbSet.where((b) => b.x == 1)` that evaluate **in-memory only** (silent correctness footgun — works locally, returns wrong data against SQL Server / Postgres / etc.) | Wrap the closure in `Expr.lambda(...)` so the provider can translate it to SQL. `dart fix` applies the change automatically. |
| `d_rocket_n_plus_one` | `for (final r in dbSet.where_(...))` followed by a navigation access (`r.user`) that triggers a per-row fetch. | Use `include_<Target>()` (the codegen helper) to do a single `IN (...)` query. |

The class names `LinqClosureRule` and `NPlusOneRule` (and the
1.x typedefs `LinqClosureLint` / `NPlusOneLint`) are still
importable from `package:d_rocket_lints/d_rocket_lints.dart`
for source compatibility with the 1.x `custom_lint_builder`
API.

## Disabling a rule

Use an `// ignore: <code>` directive on the offending line,
or disable the rule globally with `analyzer.errors:`:

```dart
// ignore: d_rocket_untranslated_closure_linq
db.users.where((b) => b.name == 'alice').toList();
```

```yaml
# analysis_options.yaml — disable the rule entirely
analyzer:
  errors:
    d_rocket_untranslated_closure_linq: ignore
    d_rocket_n_plus_one: ignore
```

## Severity

Both rules default to `warning` in the plugin. The dev
can promote them to `error` in their
`analysis_options.yaml`:

```yaml
analyzer:
  errors:
    d_rocket_untranslated_closure_linq: error
    d_rocket_n_plus_one: error
```

## Tests

14 tests across 5 files. Coverage is golden-file based
(uses `package:analyzer`'s test utilities).

```bash
dart test
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Torogoz Tech.

## Author

**Abner Velasco** — *Arquitecto de Soluciones*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Abner%20Velasco-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/abnervelasco/)
