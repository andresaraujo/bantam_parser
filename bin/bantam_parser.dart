import 'dart:typed_data';

import 'package:pratt_parser/parser.dart';
import 'package:pratt_parser/scanner.dart';

void main(List<String> arguments) {
  final source2 = '''
  # This is a comment
  4-3+2
  ''';
  final source = '2 + 3 * 4';
  final scanner = Scanner(source2);


  final parser = BantamParser(scanner);

  // Move to the first token.
  parser.advance();

  final sb = StringBuffer();
  final expr = parser.parse(Precedence.none.value);
  print(expr);
  expr.print(sb);
  print(sb);

}
