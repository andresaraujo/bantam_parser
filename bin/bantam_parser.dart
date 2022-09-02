import 'package:bantam_parser/parser.dart';
import 'package:bantam_parser/scanner.dart';

void main(List<String> arguments) {
  final source = '''
  # This is a comment
  4-3+2
  ''';
  final scanner = Scanner(source);


  final parser = BantamParser(scanner);

  // Move to the first token.
  parser.advance();

  final sb = StringBuffer();
  final expr = parser.parse(Precedence.none.value);
  print(expr);
  expr.print(sb);
  print(sb);

}
