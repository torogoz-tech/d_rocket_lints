/// 2.0.0 — entry point for the official
/// `analysis_server_plugin` system.
///
/// The Dart analysis server auto-discovers
/// this file by finding the `plugin`
/// top-level variable (which it imports and
/// reads at startup). The plugin then
/// registers both lint rules via
/// `register(PluginRegistry)`.
///
/// ## History
///
/// In 1.x + custom_lint_builder era, the
/// entry point was `lib/d_rocket_lints.dart`
/// exporting a `DRocketLintsPlugin.createPlugin()`
/// top-level function. With the migration to
/// `analysis_server_plugin` (Phase 8.5, 2026-06-22),
/// the entry point moved to `lib/main.dart` and
/// the plugin object is a top-level variable.
///
/// The old `lib/d_rocket_lints.dart` is kept
/// as a re-export shim for backward compatibility
/// with consumers that imported
/// `package:d_rocket_lints/d_rocket_lints.dart`.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/lints/linq_closure_fix.dart';
import 'src/lints/linq_closure_lint.dart';
import 'src/lints/n_plus_one_lint.dart';

/// The top-level plugin instance. The analysis
/// server auto-discovers this variable by
/// `package:d_rocket_lints/main.dart` and
/// calls `register` once.
///
/// Consumers do NOT import this file
/// directly; they activate the plugin via
/// their `analysis_options.yaml`:
///
/// ```yaml
/// analyzer:
///   plugins:
///     - d_rocket_lints
/// ```
final DRocketLintsPlugin plugin = DRocketLintsPlugin();

/// The d_rocket analyzer plugin. Registers
/// both lint rules and one IDE quick-fix:
///
/// * [LinqClosureRule] — `d_rocket_untranslated_closure_linq`
///   with associated [LinqClosureFix]
///   ("Rewrite with Expr.lambda")
/// * [NPlusOneRule] — `d_rocket_n_plus_one`
///   (no fix yet; the fix is structural —
///   add `.include_<T>()` at the call site —
///   which is too risky to auto-apply)
///
/// The plugin runs in its own isolate inside
/// the Dart analysis server. Lints are surfaced
/// by `dart analyze` and the IDE.
class DRocketLintsPlugin extends Plugin {
  @override
  String get name => 'd_rocket_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(LinqClosureRule());
    // The quick-fix is registered against the
    // LintCode (not the rule instance), and
    // via the `.new` constructor reference
    // (because each diagnostic gets its own
    // short-lived producer).
    registry.registerFixForRule(
      LinqClosureRule.code,
      LinqClosureFix.new,
    );
    registry.registerWarningRule(NPlusOneRule());
  }
}