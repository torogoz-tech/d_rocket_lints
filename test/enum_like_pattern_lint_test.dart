import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:d_rocket_lints/d_rocket_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumLikePatternLintTest);
  });
}

@reflectiveTest
class EnumLikePatternLintTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(EnumLikePatternRule());
    super.setUp();
  }

  @override
  String get analysisRule => 'd_rocket_enum_like_string';

  void test_lints_exact_alternation_on_string_field() async {
    await assertDiagnostics(
      r'''
class Pattern {
  const Pattern({required this.expression});
  final String expression;
}

class Request {
  @Pattern(expression: r'^(available|permissionDenied|timeout)$')
  String status = '';
}
''',
      [lint(175, 18)],
    );
  }

  void test_no_lint_for_enum_field() async {
    await assertNoDiagnostics(r'''
enum LocationStatus { available, permissionDenied, timeout }

class Request {
  LocationStatus status = LocationStatus.available;
}
''');
  }

  void test_no_lint_for_general_pattern() async {
    await assertNoDiagnostics(r'''
class Pattern {
  const Pattern({required this.expression});
  final String expression;
}

class Request {
  @Pattern(expression: r'^[A-Z][a-z]+$')
  String name = '';
}
''');
  }
}
