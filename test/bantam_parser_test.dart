import 'package:pratt_parser/parser.dart';
import 'package:pratt_parser/scanner.dart';
import 'package:test/test.dart';

void main() {
  test('Original test cases', () {

    // Function call.
    expectParse("a()", "a()");
    expectParse("a(b)", "a(b)");
    expectParse("a(b, c)", "a(b, c)");
    expectParse("a(b)(c)", "a(b)(c)");
    expectParse("a(b) + c(d)", "(a(b) + c(d))");
    expectParse("a(b ? c : d, e + f)", "a((b ? c : d), (e + f))");

    // Unary precedence.
    expectParse("~!-+a", "(~(!(-(+a))))");
    expectParse("a!!!", "(((a!)!)!)");

    // Unary and binary precedence.
    expectParse("-a * b", "((-a) * b)");
    expectParse("!a + b", "((!a) + b)");
    expectParse("~a ^ b", "((~a) ^ b)");
    expectParse("-a!",    "(-(a!))");
    expectParse("!a!",    "(!(a!))");

    // Binary precedence.
    expectParse("a = b + c * d ^ e - f / g", "(a = ((b + (c * (d ^ e))) - (f / g)))");

    // Binary associativity.
    expectParse("a = b = c", "(a = (b = c))");
    expectParse("a + b - c", "((a + b) - c)");
    expectParse("a * b / c", "((a * b) / c)");
    expectParse("a ^ b ^ c", "(a ^ (b ^ c))");

    // Conditional operator.
    expectParse("a ? b : c ? d : e", "(a ? b : (c ? d : e))");
    expectParse("a ? b ? c : d : e", "(a ? (b ? c : d) : e)");
    expectParse("a + b ? c * d : e / f", "((a + b) ? (c * d) : (e / f))");

    // Grouping.
    expectParse("a + (b + c) + d", "((a + (b + c)) + d)");
    expectParse("a ^ (b + c)", "(a ^ (b + c))");
    expectParse("(!a)!",    "((!a)!)");
  });
}

expectParse(String source, String expected) {
  final scanner = Scanner(source);
  final parser = BantamParser(scanner);

  // Move to the first token.
  parser.advance();

  final expr = parser.parse(Precedence.none.value);
  final sb = StringBuffer();
  expr.print(sb);
  expect(sb.toString(), expected);
}
