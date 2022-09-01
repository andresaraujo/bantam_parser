import 'package:source_span/source_span.dart';

enum TokenType {
  // single character tokens
  plus,
  minus,
  star,
  slash,
  caret,
  leftParen,
  rightParen,
  lessThan,
  greaterThan,
  equal,
  bang,
  question,
  colon,
  tilde,
  comma,

  // two character tokens
  lessThanEqual,
  greaterThanEqual,
  notEqual,

  // Literals
  number,
  identifier,
  string,

  // keywords
  and,
  or,
  $true,
  $false,
  $null,
  $comment,

  // Special tokens
  err,
  eof;

  @override
  String toString() => name;
}

class NumericToken extends Token {
  final String beforeDecimal;
  final bool hasDecimal;
  final String? afterDecimal;

  NumericToken(FileSpan span,
      {required this.beforeDecimal, required this.hasDecimal, required this.afterDecimal})
      : super(type: TokenType.number, span: span);

  num get parsedValue {
     final before = int.parse(beforeDecimal);

     if (!hasDecimal) {
       return before;
     } else if (afterDecimal != null) {
       final after = int.parse(afterDecimal!);
       return before + double.parse('.$after');
     } else {
       // The number end with a dot, but no digits after it. "5."
       return before.toDouble();
     }
  }

  @override
  toString() {
    final buffer = StringBuffer();
    buffer.write(beforeDecimal);

    if (hasDecimal) {
      buffer.write('.');
    }

    if (afterDecimal != null) {
      buffer.write(afterDecimal);
    }
    return buffer.toString();
  }
}

class ErrorToken extends Token {
  final String message;

  ErrorToken({required super.span, required this.message})
      : super(type: TokenType.err);

  @override
  String toString() {
    return span.message(message);
  }
}

class Token {
  Token({required this.type, required this.span});

  final TokenType type;
  final FileSpan span;

  String get lexeme => span.text;

  @override
  toString() => '$type $lexeme';
}
