# d_rocket_lints 2.2.1

Release date: 2026-11-19

This release updates the consumer documentation to the modern Dart analyzer
plugin configuration. The rule implementations and diagnostic behavior are
unchanged.

## Correct configuration

Add the plugin at the top level of the root `analysis_options.yaml`:

```yaml
plugins:
  d_rocket_lints: ^2.2.1
```

Do not use the deprecated legacy form:

```yaml
analyzer:
  plugins:
    - d_rocket_lints
```

After changing the top-level `plugins` section, restart the Dart Analysis
Server or restart the IDE.

## Diagnostics

The rules remain:

- `d_rocket_untranslated_closure_linq`
- `d_rocket_n_plus_one`

When suppressing or changing severity, use the plugin-qualified diagnostic
codes, for example:

```yaml
analyzer:
  errors:
    d_rocket_lints/d_rocket_n_plus_one: warning
```
