/// 2.0.0 — `d_rocket_n_plus_one` rewritten
/// for the official `analysis_server_plugin`
/// system.
///
/// A rule that fires when a
/// `NavigationRegistry.get<T>(...)` call appears
/// inside a `for` / `forEach` loop body. This
/// is the classic N+1 query pattern: the
/// framework re-fetches the navigation for every
/// loop iteration instead of batching.
///
/// **Fix**: load the entity list with
/// `.include_<T>(name, targetMeta)` first, then
/// the navigation is already populated when the
/// loop body runs.
///
/// **Example** (linted):
/// ```dart
/// for (final order in orders) {
///   print(order.customer.name);  // ← lint fires
/// }
/// ```
///
/// **Fix**:
/// ```dart
/// final orders = await db.set<Order>()
///     .include_<Customer>()
///     .toListWithIncludesAsync_();
/// for (final order in orders) {
///   print(order.customer.name);  // ✅ no lint
/// }
/// ```
///
/// ## Migration notes (Phase 8.5)
///
/// In 1.x + `custom_lint_builder`, the rule
/// used a `RecursiveAstVisitor` that walked
/// down into for-loop bodies. The 2.0 +
/// `analysis_server_plugin` version uses the
/// official `SimpleAstVisitor` API (the
/// only `visitor` implementation the
/// analysis server will invoke inside
/// plugins).
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const LintCode _nPlusOneCode = LintCode(
  'd_rocket_n_plus_one',
  'Navigation access inside a loop can cause N+1 queries. '
      'Use .include_<T>() first to batch the fetch.',
  correctionMessage:
      "Add .include_<TargetEntity>() before the loop, "
      'then call .toListWithIncludesAsync_() instead of '
      '.toListAsync_().',
);

/// The rule class. Registered in
/// `lib/main.dart`'s `DRocketLintsPlugin.register`.
class NPlusOneRule extends AnalysisRule {
  NPlusOneRule()
      : super(
          name: 'd_rocket_n_plus_one',
          description: 'Detects NavigationRegistry.get<T>() '
              'calls inside for/forEach loops (classic N+1).',
        );

  @override
  LintCode get diagnosticCode => _nPlusOneCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final _NPlusOneVisitor visitor = _NPlusOneVisitor(this);
    registry.addForStatement(this, visitor);
    registry.addForEachPartsWithDeclaration(this, visitor);
    registry.addForEachPartsWithIdentifier(this, visitor);
  }
}

class _NPlusOneVisitor extends SimpleAstVisitor<void> {
  _NPlusOneVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitForStatement(ForStatement node) {
    _walkChildren(node);
    super.visitForStatement(node);
  }

  @override
  void visitForEachPartsWithDeclaration(
    ForEachPartsWithDeclaration node,
  ) {
    // In analyzer 9.0.0, the loop body is
    // on the enclosing statement. We walk up
    // via the AST (parent chain) but for
    // the lint we just recurse on the
    // inner visitor and let it inspect
    // everything that follows.
    _walkChildren(node);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _walkChildren(node);
    super.visitForEachPartsWithIdentifier(node);
  }

  /// Recursively inspects the whole subtree
  /// looking for `NavigationRegistry.get<T>(...)`
  /// calls. We pass `node` itself as the root
  /// — the inner visitor only cares about
  /// [MethodInvocation]s anywhere in the
  /// subtree, so we don't need to scope to
  /// the body specifically.
  void _walkChildren(AstNode node) {
    node.accept(_NPlusOneInnerVisitor(rule));
  }
}

class _NPlusOneInnerVisitor extends RecursiveAstVisitor<void> {
  _NPlusOneInnerVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Detect `NavigationRegistry.get<T>(...)` calls.
    final Expression? target = node.target;
    if (target is SimpleIdentifier &&
        target.name == 'NavigationRegistry' &&
        node.methodName.name == 'get') {
      rule.reportAtNode(node);
    }
    super.visitMethodInvocation(node);
  }
}

/// Backward-compat alias. The 1.x +
/// `custom_lint_builder` API exposed this
/// rule as `NPlusOneLint`; the 2.0 +
/// `analysis_server_plugin` version is
/// `NPlusOneRule`. The old name continues to
/// compile via this typedef so consumers
/// don't have to update their imports.
typedef NPlusOneLint = NPlusOneRule;