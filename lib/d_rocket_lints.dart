/// 2.0.0 — `d_rocket_lints` public API shim.
///
/// The 1.x API lived at
/// `package:d_rocket_lints/d_rocket_lints.dart`
/// (this file). In Phase 8.5 we migrated the
/// plugin to the official `analysis_server_plugin`
/// system; the entry point is now
/// `package:d_rocket_lints/main.dart` (which
/// exports a top-level `plugin` variable for
/// the analysis server to import).
///
/// This file is preserved as a backward-compat
/// shim. Consumers that imported from
/// `package:d_rocket_lints/d_rocket_lints.dart`
/// continue to work — the public API surface
/// is identical, just backed by the new
/// `AnalysisRule` (was `LintRule`) classes.
///
/// ## What's new in 2.0
///
/// * Both lint rules are now `AnalysisRule`s
///   (the official `analysis_server_plugin` base).
///   Typedef aliases (`LinqClosureLint`,
///   `NPlusOneLint`) keep the 1.x names compiling.
/// * Auto-discovered by `dart analyze` — no
///   `dart run custom_lint` step needed.
/// * Activate via `analysis_options.yaml`:
///   ```yaml
///   analyzer:
///     plugins:
///       - d_rocket_lints
///   ```
///
/// ## What stays the same
///
/// * The two diagnostic codes
///   (`d_rocket_untranslated_closure_linq`
///   and `d_rocket_n_plus_one`).
/// * The user-facing messages (so IDE squiggles
///   look identical).
/// * The CLI auto-rewriter
///   (`dart run d_rocket:closure transform-file`).
library;

export 'src/lints/linq_closure_lint.dart'
    show
        LinqClosureLint, // = LinqClosureRule (typedef)
        LinqClosureRule;
export 'src/lints/linq_closure_fix.dart' show LinqClosureFix;
export 'src/lints/n_plus_one_lint.dart'
    show NPlusOneLint, // = NPlusOneRule (typedef)
    NPlusOneRule;
// The Plugin entry point lives at
// `package:d_rocket_lints/main.dart` (the
// analysis server reads that file, not this
// one).
export 'main.dart' show DRocketLintsPlugin;