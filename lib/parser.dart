import 'token.dart';
import 'scanner.dart';

// <editor-fold desc="expressions">
abstract class Expression {
  void print(StringBuffer sb);
}

class PostfixExpression implements Expression {
  PostfixExpression(this.left, this.operator);
  final Expression left;
  final Token operator;

  @override
  void print(StringBuffer sb) {
    sb.write('(');
    left.print(sb);
    sb.write('${operator.lexeme})');
  }
}

class PrefixExpression implements Expression {
  PrefixExpression(this.operator, this.right);
  final Token operator;
  final Expression right;

  @override
  void print(StringBuffer sb) {
    sb.write('(${operator.lexeme}');
    right.print(sb);
    sb.write(')');
  }
}

class OperatorExpression implements Expression {
  OperatorExpression(this.left, this.operator, this.right);
  final Expression left;
  final Token operator;
  final Expression right;
  @override
  void print(StringBuffer sb) {
    sb.write('(');
    left.print(sb);
    sb.write(' ${operator.lexeme} ');
    right.print(sb);
    sb.write(')');
  }
}

class ConditionalExpression implements Expression {
  ConditionalExpression(this.condition, this.thenExpression, this.elseExpression);
  final Expression condition;
  final Expression thenExpression;
  final Expression elseExpression;
  @override
  void print(StringBuffer sb) {
    sb.write('(');
    condition.print(sb);
    sb.write(' ? ');
    thenExpression.print(sb);
    sb.write(' : ');
    elseExpression.print(sb);
    sb.write(')');
  }
}

class LiteralExpression implements Expression {
  LiteralExpression(this.value);
  final Object? value;
  @override
  void print(StringBuffer sb) {
    sb.write(value);
  }
}

class IdentifierExpression implements Expression {
  IdentifierExpression(this.name);
  final String name;
  @override
  void print(StringBuffer sb) {
    sb.write(name);
  }
}

class CallExpression implements Expression {
  CallExpression(this.callee, this.arguments);
  final Expression callee;
  final List<Expression> arguments;
  @override
  void print(StringBuffer sb) {
    callee.print(sb);
    sb.write('(');
    for (int i = 0; i < arguments.length; i++) {
      if (i > 0) {
        sb.write(', ');
      }
      arguments[i].print(sb);
    }
    sb.write(')');
  }
}

class AssignmentExpression implements Expression {
  AssignmentExpression(this.identifier, this.operator, this.right);
  final Expression identifier;
  final Token operator;
  final Expression right;
  @override
  void print(StringBuffer sb) {
    sb.write('(');
    identifier.print(sb);
    sb.write(' ${operator.lexeme} ');
    right.print(sb);
    sb.write(')');
  }
}

// </editor-fold>

/// Represents the associativity of an operator.
/// a + b + c is left-associative
/// a ^ b ^ c is right-associative
enum Associativity { left, right }

/// Represents the precedence levels used by infix operators.
/// Determine how infix operators are grouped.
/// a + b * c -> (a + (b * c)) because * has higher precedence than +
enum Precedence {
  none(0),
  assignment(1), // =
  or(2),
  and(2),
  equality(3), // == !=
  comparison(4), // < > <= >=
  term(5), // + -
  product(6), // * /
  exponent(7), // ^
  unary(8), // -x !x
  postfix(9), // x++ x--
  call(10), // x(...)
  primary(11); // x

  const Precedence(this.value);
  final int value;
}

// <editor-fold desc="parselets">
abstract class PrefixParselet {
  Expression parse(Parser parser, Token token);
}
abstract class InfixParselet {
  Expression parse(Parser parser, Expression expression,Token token);
  int get precedence;
}

class PostfixOperatorParselet implements InfixParselet {
  PostfixOperatorParselet(this.precedence);

  @override
  final int precedence;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    return PostfixExpression(left, token);
  }
}

class PrefixOperatorParselet implements PrefixParselet {
  PrefixOperatorParselet(this.precedence);

  final int precedence;

  @override
  Expression parse(Parser parser, Token token) {
    var right  = parser.parse(precedence);
    return PrefixExpression(token, right);
  }
}

class BinaryOperatorParselet implements InfixParselet {
  BinaryOperatorParselet(this.precedence, {required this.associativity});
  @override
  final int precedence;
  final Associativity associativity;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var right = parser.parse(precedence - (associativity == Associativity.right ? 1 : 0));
    return OperatorExpression(left, token, right);
  }
}

class PrimaryParselet implements PrefixParselet {
  @override
  Expression parse(Parser parser, Token token) {
    if (token.type == TokenType.$true) {
      return LiteralExpression(true);
    }
    if (token.type == TokenType.$false) {
      return LiteralExpression(false);
    }
    if (token.type == TokenType.$null) {
      return LiteralExpression(null);
    }
    if (token.type == TokenType.number ) {
      return LiteralExpression((token as NumericToken).parsedValue);
    }
    if (token.type == TokenType.string) {
      return LiteralExpression(token.lexeme);
    }

    // If wanted to extend the language to support
    // only a set of identifiers, this is the place to do it.

    return IdentifierExpression(token.lexeme);

    // throw ParseException('Unexpected token ${token.type}');
  }
}

class ConditionParselet implements InfixParselet {
  @override
  final int precedence = Precedence.comparison.value;
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final thenExpression = parser.parse(Precedence.none.value);
    parser._consume(TokenType.colon, 'Expected : after condition');

    // precedence is one less than the next expression to make it right-associative
    // in case there is more than one condition expression
    // a ? b ? c : d : e -> (a ? (b ? c : d) : e)
    final elseExpression = parser.parse(precedence - 1);
    return ConditionalExpression(left, thenExpression, elseExpression);
  }
}

class GroupParselet implements PrefixParselet {
  @override
  Expression parse(Parser parser, Token token) {
    final expression = parser.parse(Precedence.none.value);
    parser._consume(TokenType.rightParen, 'Expected ) after group');
    return expression;
  }
}

class CallParselet implements InfixParselet {
  @override
  final int precedence = Precedence.call.value;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final arguments = <Expression>[];
    while (parser._current.type != TokenType.rightParen) {
      arguments.add(parser.parse(Precedence.none.value));
      if (parser.current.type != TokenType.rightParen) {
        parser._consume(TokenType.comma, 'Expected , after argument');
      }
    }
    parser._consume(TokenType.rightParen, 'Expected ) after arguments');
    return CallExpression(left, arguments);
  }
}

/// Parses assignment expressions.
/// a = b, where a is an identifier and b is an expression.
/// expressions are right-associative.
/// a = b = c -> (a = (b = c))
class AssignParselet implements InfixParselet {
  @override
  final int precedence = Precedence.assignment.value;
  @override
  Expression parse(Parser parser, Expression left, Token token) {
    final right = parser.parse(precedence - 1); // one less, to make it right-associative

    if (left is! IdentifierExpression) {
      throw parser._error(token, 'Left hand side of assignment must be an identifier');
    }

    return AssignmentExpression(left, token,  right);
  }
}
// </editor-fold>

class Parser {
  Parser(this.scanner);
  final Scanner scanner;

  late Token _current = Token(type: TokenType.eof, span: scanner.file.span(0));
  late Token _previous;

  Token get current => _current;
  Token get previous => _previous;
  set current(Token token) {
    _previous = _current;
    _current = token;
  }

  bool hadError = false;

  final Map<TokenType, PrefixParselet> _prefixParselets = {};
  final Map<TokenType, InfixParselet> _infixParselets = {};

  void registerPrefix(TokenType type, PrefixParselet parselet) {
    _prefixParselets[type] = parselet;
  }

  void registerInfix(TokenType type, InfixParselet parselet) {
    _infixParselets[type] = parselet;
  }


  parse([int precedence = 0]) {
    advance();
    final prefix = _prefixParselets[_previous.type];

    if (prefix == null) {
      throw ParseException('No prefix parselet for ${_previous.type}');
    }

    var left = prefix.parse(this, _previous);

    while (precedence < _getPrecedence()) {
      advance();

      final infix = _infixParselets[_previous.type];
      if (infix == null) {
        throw ParseException('No infix parselet for ${_previous.type}');
      }
      left = infix.parse(this, left, _previous);
    }
    return left;
  }

  int _getPrecedence() {
    final infix = _infixParselets[_current.type];
    if (infix != null) {
      return infix.precedence;
    }
    return 0;
  }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  void _consume(TokenType type, String errorMessage) {
    if (_check(type)) {
      advance();
      return;
    }
    throw _error(_current, errorMessage);
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) {
      return false;
    }
    return type == _current.type;
  }

  void advance() {
    _previous = _current;
    for (;;) {
      _current = scanner.scanToken();
      if (_current.type != TokenType.err) {
        break;
      }
      _error(_current, current.span.text);
    }
  }

  bool _isAtEnd() {
    return _current.type == TokenType.eof;
  }

  ParseException _error(Token token, String message) {
    hadError = true;
    throw ParseException(message);
  }
}

class BantamParser extends Parser {
  BantamParser(super.scanner) {

    registerPrefix(TokenType.identifier, PrimaryParselet());
    registerPrefix(TokenType.leftParen, GroupParselet());


    registerPrefix(TokenType.plus, PrefixOperatorParselet(Precedence.unary.value));
    registerPrefix(TokenType.minus, PrefixOperatorParselet(Precedence.unary.value));
    registerPrefix(TokenType.tilde, PrefixOperatorParselet(Precedence.unary.value));
    registerPrefix(TokenType.bang, PrefixOperatorParselet(Precedence.unary.value));

    registerInfix(TokenType.equal, AssignParselet());
    registerInfix(TokenType.leftParen, CallParselet());
    registerInfix(TokenType.bang, PostfixOperatorParselet(Precedence.postfix.value));

    registerInfix(TokenType.question, ConditionParselet());
    registerInfix(TokenType.or, BinaryOperatorParselet(Precedence.or.value, associativity: Associativity.left));
    registerInfix(TokenType.and, BinaryOperatorParselet(Precedence.and.value, associativity: Associativity.left));

    registerInfix(TokenType.plus, BinaryOperatorParselet(Precedence.term.value, associativity: Associativity.left));
    registerInfix(TokenType.minus, BinaryOperatorParselet(Precedence.term.value, associativity: Associativity.left));
    registerInfix(TokenType.star, BinaryOperatorParselet(Precedence.product.value, associativity: Associativity.left));
    registerInfix(TokenType.slash, BinaryOperatorParselet(Precedence.product.value, associativity: Associativity.left));
    registerInfix(TokenType.caret, BinaryOperatorParselet(Precedence.exponent.value, associativity: Associativity.right));

    // Additional parselets not included in original Bantam grammar
    registerPrefix(TokenType.number, PrimaryParselet());
    registerPrefix(TokenType.string, PrimaryParselet());
    registerPrefix(TokenType.$false, PrimaryParselet());
    registerPrefix(TokenType.$true, PrimaryParselet());
    registerPrefix(TokenType.$null, PrimaryParselet());
  }
}

class ParseException implements Exception {
  ParseException(this.message);
  final String message;

  @override
  String toString() => message;
}
