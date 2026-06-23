// 2.0.0 — IDE quick-fix for the
// `d_rocket_untranslated_closure_linq` rule.
//
// Associated with [LinqClosureRule.code]; the
// IDE surfaces this as a lightbulb next to
// the diagnostic. When applied, it rewrites:
//
//   q.where_((p) => p.age > 18);
//
// into:
//
//   q.where_(
//     Expr.lambda(
//       [Expr.param('p')],
//       /* TODO: rewrite body via Expr.lambda/Expr.op/Expr.col/Expr.lit */
//     ),
//   );
//
// The placeholder body is intentional:
// closure bodies in LINQ can range from
// simple binary expressions (`a > b`) to
// complex statement blocks (`{ final x = …; return x > 18; }`)
// and method invocations, none of which can be
// safely auto-rewritten without running the
// full `dart run d_rocket:closure transform-file`
// command (which uses the parser + type
// information to build the equivalent Expr
// tree).
//
// The IDE fix is intentionally lightweight:
// it handles the parameter list (always
// well-formed) and emits a TODO for the body.
// This way, the user can:
//
// 1. Apply the fix in the IDE (instant).
// 2. Manually fill in the body (a few seconds
//    for a typical `=>` expression).
//
// …instead of having to do BOTH steps by hand.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'linq_closure_lint.dart';

/// The `FixKind` for this quick-fix. Shown in
/// the IDE as the lightbulb action label.
const FixKind _rewriteWithExprLambdaKind = FixKind(
  // Unique id; convention is `<package>.<fix>`.
  'd_rocket_lints.rewrite_closure_as_expr_lambda',
  DartFixKindPriority.standard,
  "Rewrite with Expr.lambda",
);

/// The [CorrectionProducer] (quick-fix)
/// associated with [LinqClosureRule.code].
///
/// Constructor signature must be
/// `({required CorrectionProducerContext context})`
/// because that's how `analysis_server_plugin`
/// registers it (via the `.new` constructor
/// reference in `registerFixForRule`).
class LinqClosureFix extends ResolvedCorrectionProducer {
  LinqClosureFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _rewriteWithExprLambdaKind;

  /// Public accessor for the fix id.
  /// Useful for tests and for consumers
  /// that want to enable/disable the fix
  /// by id in their `analysis_options.yaml`.
  static String get fixKindId => _rewriteWithExprLambdaKind.id;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final MethodInvocation invocation = node as MethodInvocation;
    final NodeList<Expression> args = invocation.argumentList.arguments;
    if (args.isEmpty) return;
    final Expression firstArg = args.first;
    if (firstArg is! FunctionExpression) return;

    final String rewrite = buildRewriteText(firstArg);

    await builder.addDartFileEdit(file, (DartFileEditBuilder b) {
      b.addReplacement(range.node(firstArg), (DartEditBuilder editBuilder) {
        editBuilder.write(rewrite);
      });
    });
  }

  /// Builds the replacement source text for
  /// the given closure. The replacement is a
  /// valid Dart expression that compiles in
  /// any context where `Expr` is in scope —
  /// the body is a TODO placeholder because
  /// closure bodies can't be safely auto-
  /// translated to `Expr` calls.
  ///
  /// Public (not private) so it can be
  /// unit-tested directly without going
  /// through the analyzer-plugin pipeline.
  static String buildRewriteText(FunctionExpression closure) {
    final FormalParameterList? paramList = closure.parameters;
    final String params = paramsToExprListText(
      paramList?.parameters ?? const <FormalParameter>[],
    );

    // The body of a `(p) => body` is either
    //   - a single expression: `p.age > 18`
    //   - a statement block: `{ final x = …; return x > 18; }`
    // In both cases we emit a TODO placeholder
    // pointing at the `d_rocket:closure`
    // auto-rewriter for the body. The user
    // can either fill in the body manually
    // (best for `=>` expressions) or run
    // `dart run d_rocket:closure transform-file`
    // on the file (best for statement blocks).
    return 'Expr.lambda(\n'
        '      $params,\n'
        "      /* TODO: rewrite closure body using Expr.lambda / "
        'Expr.op / Expr.col / Expr.lit; or run '
        "'dart run d_rocket:closure transform-file <path>' */"
        ',)';
  }

  /// Converts the closure's parameter list
  /// (e.g. `(p)`, `(p, q)`) into the equivalent
  /// `Expr.param(...)` literal list
  /// (e.g. `[Expr.param('p')]`,
  /// `[Expr.param('p'), Expr.param('q')]`).
  ///
  /// Type annotations are preserved as type
  /// arguments:
  /// `(Person p, Order o)` →
  /// `[Expr.param<Person>('p'), Expr.param<Order>('o')]`.
  ///
  /// Public so it's testable in isolation.
  static String paramsToExprListText(List<FormalParameter> parameters) {
    if (parameters.isEmpty) {
      // `() => body` — empty parameter list.
      // In d_rocket LINQ, this means the
      // expression doesn't depend on the
      // row (e.g. `where_(() => true)`).
      return '[]';
    }
    final StringBuffer buf = StringBuffer('[');
    for (int i = 0; i < parameters.length; i++) {
      if (i > 0) buf.write(', ');
      final FormalParameter p = parameters[i];
      // We only handle the common
      // SimpleFormalParameter case (`p`
      // or `Person p`). Anything more
      // exotic (optional, named, destructured)
      // gets a `/* TODO */` marker.
      if (p is SimpleFormalParameter) {
        final Token? nameTok = p.name;
        final String? name = nameTok?.lexeme;
        if (name == null) {
          buf.write('/* TODO: handle non-named param */');
        } else {
          // Get the type name (if any) from
          // the type annotation's source text.
          // We use `toSource()` because
          // `TypeAnnotation` is a sealed class
          // in analyzer 9.0.0 (no `name` getter
          // at the base level). The simple
          // case `Person` is covered, and
          // // complex cases like
          // `List<Person>` are also preserved
          // verbatim.
          final TypeAnnotation? type = p.type;
          final String? typeText = type?.toSource();
          if (typeText != null && typeText.isNotEmpty) {
            buf.write("Expr.param<$typeText>('$name')");
          } else {
            buf.write("Expr.param('$name')");
          }
        }
      } else {
        buf.write('/* TODO: handle '
            '${p.runtimeType} '
            'param */');
      }
    }
    buf.write(']');
    return buf.toString();
  }
}