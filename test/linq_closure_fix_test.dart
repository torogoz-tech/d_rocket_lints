// 2.0.0 — unit tests for the
// `LinqClosureFix` transformation logic.
//
// We test the *pure* logic
// (`buildRewriteText`, `paramsToExprListText`)
// directly, without going through the
// full analyzer-plugin pipeline. The
// full pipeline is exercised in the
// `main_test.dart` smoke test which
// verifies the fix is registered against
// the right `LintCode`.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:d_rocket_lints/d_rocket_lints.dart';
import 'package:test/test.dart';

void main() {
  group('2.0.0 — LinqClosureFix', () {
    test('fixKindId is stable', () {
      // Bumping this id would break consumers
      // that disable the fix by id in
      // analysis_options.yaml.
      expect(
        LinqClosureFix.fixKindId,
        equals('d_rocket_lints.rewrite_closure_as_expr_lambda'),
      );
    });

    group('paramsToExprListText', () {
      test('single untyped param', () {
        final src = 'void main() { q.where_((p) => true); }';
        final FunctionExpression closure = _parseClosure(src);
        expect(
          LinqClosureFix.paramsToExprListText(closure.parameters?.parameters ?? const <FormalParameter>[]),
          equals("[Expr.param('p')]"),
        );
      });

      test('two untyped params', () {
        final src = 'void main() { q.where_((p, q) => true); }';
        final FunctionExpression closure = _parseClosure(src);
        expect(
          LinqClosureFix.paramsToExprListText(closure.parameters?.parameters ?? const <FormalParameter>[]),
          equals("[Expr.param('p'), Expr.param('q')]"),
        );
      });

      test('single typed param', () {
        final src = '''
class Person { int age = 0; }
void main() { q.where_((Person p) => p.age > 18); }
''';
        final FunctionExpression closure = _parseClosure(src);
        expect(
          LinqClosureFix.paramsToExprListText(closure.parameters?.parameters ?? const <FormalParameter>[]),
          equals("[Expr.param<Person>('p')]"),
        );
      });

      test('mixed typed params', () {
        final src = '''
class Person {}
class Order {}
void main() { q.where_((Person p, Order o) => true); }
''';
        final FunctionExpression closure = _parseClosure(src);
        expect(
          LinqClosureFix.paramsToExprListText(closure.parameters?.parameters ?? const <FormalParameter>[]),
          equals("[Expr.param<Person>('p'), Expr.param<Order>('o')]"),
        );
      });

      test('empty params', () {
        final src = 'void main() { q.where_(() => true); }';
        final FunctionExpression closure = _parseClosure(src);
        expect(
          LinqClosureFix.paramsToExprListText(closure.parameters?.parameters ?? const <FormalParameter>[]),
          equals('[]'),
        );
      });
    });

    group('buildRewriteText', () {
      test('single param: emits Expr.lambda with TODO body', () {
        final src = 'void main() { q.where_((p) => true); }';
        final FunctionExpression closure = _parseClosure(src);
        final String out = LinqClosureFix.buildRewriteText(closure);
        expect(out, contains("Expr.param('p')"));
        expect(out, contains('TODO'));
        expect(out, startsWith('Expr.lambda('));
      });

      test('two params: emits Expr.lambda with both params', () {
        final src = 'void main() { q.where_((p, q) => true); }';
        final FunctionExpression closure = _parseClosure(src);
        final String out = LinqClosureFix.buildRewriteText(closure);
        expect(out, contains("Expr.param('p')"));
        expect(out, contains("Expr.param('q')"));
      });

      test('typed params: emits Expr.param<Type> form', () {
        final src = '''
class Person { int age = 0; }
void main() { q.where_((Person p) => p.age > 18); }
''';
        final FunctionExpression closure = _parseClosure(src);
        final String out = LinqClosureFix.buildRewriteText(closure);
        expect(out, contains("Expr.param<Person>('p')"));
      });

      test('empty params: emits [] literal', () {
        final src = 'void main() { q.where_(() => true); }';
        final FunctionExpression closure = _parseClosure(src);
        final String out = LinqClosureFix.buildRewriteText(closure);
        expect(out, contains('[]'));
      });
    });
  });
}

/// Parses a Dart source snippet and returns
/// the `FunctionExpression` inside the
/// single `MethodInvocation` it contains.
FunctionExpression _parseClosure(String src) {
  final CompilationUnit unit = parseString(
    content: src,
    throwIfDiagnostics: false,
  ).unit;
  MethodInvocation? invocation;
  unit.accept(_InvocationFinder((MethodInvocation m) {
    if (invocation != null) {
      throw StateError('test source contains multiple invocations');
    }
    invocation = m;
  }));
  if (invocation == null) {
    throw StateError('test source contains no MethodInvocation');
  }
  final Expression firstArg = invocation!.argumentList.arguments.first;
  if (firstArg is! FunctionExpression) {
    throw StateError(
      'test source first arg is not a FunctionExpression: $firstArg',
    );
  }
  return firstArg;
}

class _InvocationFinder extends GeneralizingAstVisitor<void> {
  _InvocationFinder(this._onInvocation);

  final void Function(MethodInvocation) _onInvocation;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _onInvocation(node);
    super.visitMethodInvocation(node);
  }
}