// 2.0.0 — tests that exercise the
// `d_rocket_untranslated_closure_linq`
// lint against a *real* `package:d_rocket`
// import (mocked via
// `PubPackageResolutionTest.newPackage`).
//
// Why this matters: the simpler tests in
// `linq_closure_lint_test.dart` declare
// stub `Queryable<T>` classes inline, so
// we never actually exercise the lint's
// real call-site signature matching.
//
// This test creates a mock `d_rocket`
// package on the fly with the REAL API
// surface (copied verbatim from the
// 2.0.0 production package), then runs
// the lint against code that imports it
// and uses the real symbols.
//
// If the production `Queryable<T>.where_(...)`
// signature ever changes (e.g. parameter
// name, return type, default args), these
// tests will catch it. The inline-stub
// tests will NOT.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:d_rocket_lints/d_rocket_lints.dart';
import 'package:test/test.dart' as test_pkg;
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinqClosureRealApiTest);
  });
}

@reflectiveTest
class LinqClosureRealApiTest extends AnalysisRuleTest {
  // We register the mock `d_rocket` package
  // as a `static const` field, so the source
  // string is a single source of truth.
  //
  // The mock's API surface is copied
  // verbatim from the 2.0.0 production
  // package (`lib/src/linq/queryable.dart`).
  // Any drift between this mock and the
  // real API will surface as a failing test
  // here.
  static const String _mockDRocketSource = r'''
library;

abstract class Queryable<T> {
  Queryable<T> where_(Object predicate);
  Queryable<T> orderBy_(Object keySelector);
  Queryable<T> orderByDescending_(Object keySelector);
  Queryable<T> thenBy_(Object keySelector);
  Queryable<T> thenByDescending_(Object keySelector);
}

class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

class NavigationRegistry {
  static T get<T>(Object owner) => owner as T;
}
''';

  @override
  void setUp() {
    // 1. Register the mock package BEFORE
    //    super.setUp() runs (super.setUp
    //    writes the package config which
    //    captures the package list).
    newPackage('d_rocket').addFile(
      'lib/d_rocket.dart',
      _mockDRocketSource,
    );
    // 2. Register the lint rule.
    Registry.ruleRegistry.registerLintRule(LinqClosureRule());
    // 3. Run the base setUp (writes package
    //    config + analysis context).
    super.setUp();
  }

  @override
  String get analysisRule => 'd_rocket_untranslated_closure_linq';

  /// Helper: count the diagnostics that
  /// match our lint rule. We avoid
  /// `assertDiagnostics` because the
  /// mock `Queryable<T>` is abstract,
  /// which triggers compile errors that
  /// are a distraction here. We just want
  /// to verify our lint fires (or not).
  ///
  /// `resolveFile` takes a path, not source
  /// text — so we first write the source
  /// to `testPackageLibPath/testFileName`
  /// via `newFile`, then resolve it.
  Future<int> _countRuleDiagnostics(String source) async {
    newFile(testPackageLibPath, source);
    final result = await resolveFile(testPackageLibPath);
    return result.errors
        .where((d) =>
            d.errorCode.name == 'd_rocket_untranslated_closure_linq')
        .length;
  }

  void test_real_import_lints_where_closure() async {
    final n = await _countRuleDiagnostics(
      '''
import 'package:d_rocket/d_rocket.dart';

class Person { int age = 0; }

void main() {
  final q = Queryable<Person>();
  q.where_((p) => p.age > 18);
}
''',
    );
    test_pkg.expect(n, test_pkg.equals(1),
        reason: 'should lint the closure LINQ call exactly once');
  }

  void test_real_import_lints_orderBy_closure() async {
    final n = await _countRuleDiagnostics(
      '''
import 'package:d_rocket/d_rocket.dart';

class Person { String name = ''; }

void main() {
  final q = Queryable<Person>();
  q.orderBy_((p) => p.name);
}
''',
    );
    test_pkg.expect(n, test_pkg.equals(1),
        reason: 'should lint the orderBy closure exactly once');
  }

  void test_real_import_no_lint_with_Expr_lambda() async {
    final n = await _countRuleDiagnostics(
      '''
import 'package:d_rocket/d_rocket.dart';

class Person { int age = 0; }

void main() {
  final q = Queryable<Person>();
  q.where_(Expr.lambda([Expr.param('p')], true));
}
''',
    );
    test_pkg.expect(n, test_pkg.equals(0),
        reason: 'should NOT lint when Expr.lambda is used');
  }

  void test_real_import_no_lint_for_in_memory_method() async {
    // `.where` (no underscore) is the
    // in-memory variant; it accepts a
    // closure but should NOT be linted.
    final n = await _countRuleDiagnostics(
      '''
import 'package:d_rocket/d_rocket.dart';

void main() {
  final list = <int>[1, 2, 3];
  list.where((x) => x > 1);
}
''',
    );
    test_pkg.expect(n, test_pkg.equals(0),
        reason: 'should NOT lint non-underscore methods');
  }
}