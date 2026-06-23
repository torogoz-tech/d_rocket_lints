/// 2.0.0 — `d_rocket_untranslated_closure_linq`
/// rewritten for the official
/// `analysis_server_plugin` system.
///
/// A rule that fires when a closure LINQ
/// call (`q.where_((t) => …)`, `q.orderBy_((t) => …)`,
/// etc.) is detected. The closure runs
/// in-memory only — for SQL translation the
/// user should run the auto-rewriter CLI:
///
/// ```bash
/// dart run d_rocket:closure transform-file <path>
/// ```
///
/// ## Migration notes (Phase 8.5)
///
/// Before 2.0.0, this rule was a
/// `custom_lint_builder.LintRule`. The 1.x
/// version was custom-lint-only and required
/// `dart run custom_lint` to surface warnings.
///
/// In 2.0.0, this rule is an
/// `AnalysisRule` (the official `analysis_server_plugin`
/// base class) and is auto-discovered by
/// `dart analyze`. No extra build step.
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// The `d_rocket_untranslated_closure_linq`
/// diagnostic. Declared as a top-level const
/// (not `static const` on a class) so it can
/// be referenced from both
/// [LinqClosureRule] (via `diagnosticCode`)
/// and `main.dart` (via
/// `registry.registerFixForRule(...)`).
const LintCode closureLinqCode = LintCode(
  'd_rocket_untranslated_closure_linq',
  'Closure LINQ calls run in-memory only; for '
      'SQL translation, rewrite with Expr.lambda(...).',
  correctionMessage:
      "Run 'dart run d_rocket:closure transform-file <path>' "
      'to auto-rewrite this file.',
);

/// The rule class. Registered in
/// `lib/main.dart`'s `DRocketLintsPlugin.register`.
class LinqClosureRule extends AnalysisRule {
  LinqClosureRule()
      : super(
          name: 'd_rocket_untranslated_closure_linq',
          description: 'Detects closure LINQ calls that run '
              'in-memory only and should be rewritten with '
              'Expr.lambda for SQL translation.',
        );

  /// Convenience accessor so callers (like
  /// `main.dart`'s `registerFixForRule`)
  /// can reference the diagnostic code
  /// without instantiating a rule instance.
  /// Same value as `closureLinqCode`.
  static LintCode get code => closureLinqCode;

  @override
  LintCode get diagnosticCode => closureLinqCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final _LinqClosureVisitor visitor = _LinqClosureVisitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _LinqClosureVisitor extends SimpleAstVisitor<void> {
  _LinqClosureVisitor(this.rule);

  final AnalysisRule rule;

  /// The closure LINQ method names we look for.
  /// These are the only methods that accept
  /// either an Expr or a closure (the `_`
  /// suffix is the d_rocket convention for
  /// "SQL-translatable variants").
  static const Set<String> _closureLinqMethods = <String>{
    'where_',
    'orderBy_',
    'orderByDescending_',
    'thenBy_',
    'thenByDescending_',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Only check calls whose method name is one
    // of our closure LINQ methods.
    final String? methodName = node.methodName.name;
    if (methodName == null) return;
    if (!_closureLinqMethods.contains(methodName)) return;

    // Only check calls whose first argument is a
    // function expression (a closure literal).
    final NodeList<Expression> args = node.argumentList.arguments;
    if (args.isEmpty) return;
    final Expression firstArg = args.first;
    // FunctionExpression is the AST node for
    // `(x) => …` arrow-form closures and
    // `(x) { … }` block-form closures alike.
    if (firstArg is! FunctionExpression) return;

    rule.reportAtNode(node);
  }
}

/// Backward-compat re-exports. The 1.x +
/// `custom_lint_builder` API exposed
/// `LinqClosureLint`, `LinqClosureFix`, and
/// `DRocketLintsPlugin` classes. The 2.0
/// migration renamed these to `LinqClosureRule`,
/// `LinqClosureFix` (now a `CorrectionProducer`),
/// and `DRocketLintsPlugin` (now an
/// `AnalysisServerPlugin` Plugin).
///
/// Consumers that imported these symbols from
/// `package:d_rocket_lints/d_rocket_lints.dart`
/// (the old entry point) continue to compile:
/// the old library file re-exports the new
/// names under their new identifiers.
typedef LinqClosureLint = LinqClosureRule;

// (The LinqClosureFix correction producer is
// defined in `lib/src/lints/linq_closure_fix.dart`.)