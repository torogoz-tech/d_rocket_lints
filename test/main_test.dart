// 2.0.0 — entry-point smoke test for
// `package:d_rocket_lints/main.dart`.
//
// The official `analysis_server_plugin`
// system discovers plugins by importing
// `lib/main.dart` and reading the top-level
// `plugin` variable. This test verifies
// that:
// 1. The plugin file is importable.
// 2. The plugin is an instance of
//    `DRocketLintsPlugin`.
// 3. The plugin has a non-empty `name`.
// 4. Both rules are registered (we invoke
//    `register` with a fake registry and
//    assert it was called twice).
//
// We keep this test separate from the
// per-rule tests (which live in
// `linq_closure_lint_test.dart` and
// `n_plus_one_lint_test.dart`) because the
// plugin metadata is logically separate
// from the rule logic.

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:d_rocket_lints/main.dart';
import 'package:test/test.dart';

void main() {
  group('2.0.0 — DRocketLintsPlugin entry point', () {
    test('plugin is exposed as a top-level variable', () {
      expect(plugin, isA<DRocketLintsPlugin>());
    });

    test('plugin has a non-empty name', () {
      expect(plugin.name, equals('d_rocket_lints'));
    });

    test('register() registers both rules + one fix', () {
      final _FakeRegistry registry = _FakeRegistry();
      plugin.register(registry);
      expect(registry.warningRules, hasLength(2));
      // We also register one quick-fix
      // (Rewrite with Expr.lambda for the
      // closure rule). The N+1 rule has no
      // fix because its fix is structural
      // (insert .include_<T>()) and too
      // risky to auto-apply.
      expect(registry.fixProducers, hasLength(1));
    });

    test('plugin extends analysis_server_plugin.Plugin', () {
      expect(plugin, isA<Plugin>());
    });
  });
}

/// A minimal `PluginRegistry` test double
/// that records calls to `registerWarningRule`.
class _FakeRegistry implements PluginRegistry {
  final List<Object> warningRules = <Object>[];
  final List<Object> lintRules = <Object>[];
  final List<Object> fixProducers = <Object>[];
  final List<Object> assistProducers = <Object>[];

  @override
  void registerWarningRule(Object rule) {
    warningRules.add(rule);
  }

  @override
  void registerLintRule(Object rule) {
    lintRules.add(rule);
  }

  @override
  void registerFixForRule(Object diagnostic, Object producer) {
    fixProducers.add(producer);
  }

  @override
  void registerAssist(Object producer) {
    assistProducers.add(producer);
  }
}