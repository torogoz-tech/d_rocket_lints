// 2.0.0 — `d_rocket_untranslated_closure_linq`
// tests (rewritten for the official
// `analysis_server_plugin` system).
//
// The test snippets declare `Queryable`,
// `Expr`, `ExprParam` inline so we
// don't need to import the full
// `d_rocket` package (the analyzer-testing
// framework doesn't have access to the
// consumer project's pubspec resolution
// unless we wire it up via
// `addPackageDep`, which is more work
// than just declaring the symbols).
//
// Test coverage:
// 1. `.where_((t) => …)` → lint fires.
// 2. `.orderBy_((t) => …)` → lint fires.
// 3. `.orderByDescending_((t) => …)` → lint fires.
// 4. `.where_(Expr.lambda(…))` → no lint
//    (already translated).
// 5. `.where` (no underscore) with closure
//    → no lint (it's the in-memory variant).
// 6. `.where_(someVariable)` (non-closure)
//    → no lint.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:d_rocket_lints/d_rocket_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinqClosureLintTest);
  });
}

@reflectiveTest
class LinqClosureLintTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(LinqClosureRule());
    super.setUp();
  }

  @override
  String get analysisRule => 'd_rocket_untranslated_closure_linq';

  // ─── POSITIVE: should lint ───

  void test_lints_where_with_closure() async {
    await assertDiagnostics(
      r'''
class Person { int age = 0; }
class Queryable<T> {
  Queryable<T> where_(Object pred) => this;
  Queryable<T> orderBy_(Object keySel) => this;
  Queryable<T> orderByDescending_(Object keySel) => this;
}
class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

void main() {
  final q = Queryable<Person>();
  q.where_((p) => p.age > 18);
}
''',
      [lint(382, 27)],
    );
  }

  void test_lints_orderBy_with_closure() async {
    await assertDiagnostics(
      r'''
class Person { String name = ''; }
class Queryable<T> {
  Queryable<T> where_(Object pred) => this;
  Queryable<T> orderBy_(Object keySel) => this;
  Queryable<T> orderByDescending_(Object keySel) => this;
}
class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

void main() {
  final q = Queryable<Person>();
  q.orderBy_((p) => p.name);
}
''',
      [lint(387, 25)],
    );
  }

  void test_lints_orderByDescending_with_closure() async {
    await assertDiagnostics(
      r'''
class Person { String name = ''; }
class Queryable<T> {
  Queryable<T> where_(Object pred) => this;
  Queryable<T> orderBy_(Object keySel) => this;
  Queryable<T> orderByDescending_(Object keySel) => this;
}
class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

void main() {
  final q = Queryable<Person>();
  q.orderByDescending_((p) => p.name);
}
''',
      [lint(387, 35)],
    );
  }

  // ─── NEGATIVE: should NOT lint ───

  void test_no_lint_when_using_Expr_lambda() async {
    await assertNoDiagnostics(
      r'''
class Person { int age = 0; }
class Queryable<T> {
  Queryable<T> where_(Object pred) => this;
}
class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

void main() {
  final q = Queryable<Person>();
  q.where_(Expr.lambda([Expr.param('p')], true));
}
''',
    );
  }

  void test_no_lint_for_non_underscore_method() async {
    // `.where` (no underscore) takes a
    // closure but is in-memory only; it's
    // not a SQL-translatable call.
    await assertNoDiagnostics(
      r'''
void main() {
  final list = <int>[1, 2, 3];
  final filtered = list.where((x) => x > 1);
  print(filtered);
}
''',
    );
  }

  void test_no_lint_for_non_closure_argument() async {
    // `.where_(someVariable)` is a valid
    // pre-built Expr, not a closure.
    await assertNoDiagnostics(
      r'''
class Person {}
class Queryable<T> {
  Queryable<T> where_(Object pred) => this;
}
class Expr {
  static Expr lambda(List<Object> params, Object body) => Expr();
  static Object param(String name) => Object();
}

void main() {
  final q = Queryable<Person>();
  final pred = Expr.lambda([Expr.param('p')], true);
  q.where_(pred);
}
''',
    );
  }
}