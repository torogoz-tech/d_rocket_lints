// 2.0.0 — `d_rocket_n_plus_one` tests
// (rewritten for the official
// `analysis_server_plugin` system).
//
// We use `analyzer_testing`'s
// `AnalysisRuleTest` base class + the
// `test_reflective_loader` to discover
// `test_*` methods. Each test case
// asserts that the rule reports the
// expected diagnostic(s) (or none) for a
// given Dart source snippet.
//
// The test snippets declare
// `NavigationRegistry` inline so we
// don't need to import the full
// `d_rocket` package (the analyzer-testing
// framework doesn't have access to the
// consumer project's pubspec resolution
// unless we wire it up via
// `addPackageDep`, which is more work
// than just declaring the symbol).
//
// Test coverage:
// 1. `forEach` with `NavigationRegistry.get`
//    inside body → lint fires.
// 2. `for (var i)` with `NavigationRegistry.get`
//    inside body → lint fires.
// 3. `NavigationRegistry.get` outside any loop
//    → no lint (it's a normal navigation).
// 4. Other `.get` calls inside loops → no lint.
// 5. `order.customer` inside loops → no lint.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:d_rocket_lints/d_rocket_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NPlusOneLintTest);
  });
}

@reflectiveTest
class NPlusOneLintTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(NPlusOneRule());
    super.setUp();
  }

  @override
  String get analysisRule => 'd_rocket_n_plus_one';

  // ─── POSITIVE: should lint ───

  void test_lints_forEach_with_NavigationRegistry_get() async {
    await assertDiagnostics(
      r'''
class Customer {}
class NavigationRegistry {
  static T get<T>(Object o) => o as T;
}
class Order {}

void main() {
  final orders = <Order>[];
  for (final order in orders) {
    final customer = NavigationRegistry.get<Customer>(order);
    print(customer);
  }
}
''',
      [
        // The diagnostic is reported on the
        // entire `NavigationRegistry.get<Customer>(order)`
        // MethodInvocation. Offset and length
        // computed empirically from the
        // expected output of the analyzer.
        lint(197, 39),
      ],
    );
  }

  void test_lints_classic_for_with_NavigationRegistry_get() async {
    await assertDiagnostics(
      r'''
class Customer {}
class NavigationRegistry {
  static T get<T>(Object o) => o as T;
}
class Order {}

void main() {
  final orders = <Order>[];
  for (var i = 0; i < orders.length; i++) {
    final order = orders[i];
    final customer = NavigationRegistry.get<Customer>(order);
    print(customer);
  }
}
''',
      [lint(238, 39)],
    );
  }

  // ─── NEGATIVE: should NOT lint ───

  void test_no_lint_when_outside_any_loop() async {
    await assertNoDiagnostics(
      r'''
class Customer {}
class NavigationRegistry {
  static T get<T>(Object o) => o as T;
}
class Order {}

void main() {
  final order = Order();
  final customer = NavigationRegistry.get<Customer>(order);
  print(customer);
}
''',
    );
  }

  void test_no_lint_when_other_method_called_in_loop() async {
    await assertNoDiagnostics(
      r'''
class Customer {}
class Order {
  Customer get customer => Customer();
}

void main() {
  final orders = <Order>[];
  for (final order in orders) {
    final customer = order.customer;
    print(customer);
  }
}
''',
    );
  }

  void test_no_lint_for_unrelated_get_call() async {
    await assertNoDiagnostics(
      r'''
class Wrapper {
  int get something => 42;
}

void main() {
  final w = Wrapper();
  final x = w.something;
  print(x);
}
''',
    );
  }
}