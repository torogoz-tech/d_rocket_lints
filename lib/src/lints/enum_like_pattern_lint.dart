import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const LintCode enumLikePatternCode = LintCode(
  'd_rocket_enum_like_string',
  'This String field restricts values to a fixed set; use an enum instead.',
  correctionMessage:
      'Declare an enum with these values and use it as the field type.',
);

/// Warns when a String field uses an exact alternation pattern that is better
/// represented by a Dart enum.
class EnumLikePatternRule extends AnalysisRule {
  EnumLikePatternRule()
    : super(
        name: 'd_rocket_enum_like_string',
        description:
            'Detects fixed-value String fields that should use an enum.',
      );

  @override
  LintCode get diagnosticCode => enumLikePatternCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFieldDeclaration(this, _EnumLikePatternVisitor(this));
  }
}

class _EnumLikePatternVisitor extends SimpleAstVisitor<void> {
  _EnumLikePatternVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final TypeAnnotation? type = node.fields.type;
    if (type is! NamedType || type.name.lexeme != 'String') return;

    for (final Annotation annotation in node.metadata) {
      if (annotation.name.name != 'Pattern') continue;
      final String? expression = _patternExpression(annotation);
      if (expression == null) continue;
      if (_fixedValues(expression) == null) continue;
      rule.reportAtNode(node.fields);
      return;
    }
  }

  String? _patternExpression(Annotation annotation) {
    for (final Argument argument
        in annotation.arguments?.arguments ?? const <Argument>[]) {
      if (argument is! NamedArgument || argument.name.lexeme != 'expression') {
        continue;
      }
      final Expression value = argument.argumentExpression;
      if (value is SimpleStringLiteral) return value.value;
      if (value is StringLiteral) return value.stringValue;
    }
    return null;
  }

  List<String>? _fixedValues(String expression) {
    final RegExp match = RegExp(
      r'^\^\(([A-Za-z_][A-Za-z0-9_]*(?:\|[A-Za-z_][A-Za-z0-9_]*)+)\)\$$',
    );
    final RegExpMatch? result = match.firstMatch(expression);
    if (result == null) return null;
    return result.group(1)!.split('|');
  }
}
