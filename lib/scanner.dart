import 'dart:typed_data';

import 'package:charcode/ascii.dart';
import 'package:source_span/source_span.dart';
import 'token.dart';

// On demand scanner.
class Scanner {

  /// The source code to be scanned.
  final String source;

  /// Represents the source as a list 16 bit integers.
  final Uint16List _charCodes;

  /// Source code being scanned.
  final SourceFile _file;

  int _start = 0;
  int _current = 0;

  Scanner(this.source)
      : _file = SourceFile.fromString(source),
        _charCodes = Uint16List.fromList(source.codeUnits);

  SourceFile get file => _file;

  Token scanToken() {
    _skipWhitespace();

    _start = _current;
    if (_isAtEnd) return Token(type: TokenType.eof, span: _file.span(_file.length));

    final char = _nextChar();

    if (isAlpha(char)) return _identifier();

    if (isDigit(char)) {
      return _number(char);
    }

    switch (char) {
      case $openParen:
        return _makeToken(TokenType.leftParen);
      case $closeParen:
        return _makeToken(TokenType.rightParen);
      case $comma:
        return _makeToken(TokenType.comma);
      case $minus:
        return _makeToken(TokenType.minus);
      case $plus:
        return _makeToken(TokenType.plus);
      case $slash:
        return _makeToken(TokenType.slash);
      case $asterisk:
        return _makeToken(TokenType.star);
      case $tilde:
        return _makeToken(TokenType.tilde);
      case $equal:
        return _makeToken(TokenType.equal);
      case $exclamation:
        return _makeToken(TokenType.bang);
      case $question:
        return _makeToken(TokenType.question);
      case $colon:
        return _makeToken(TokenType.colon);
      case $caret:
        return _makeToken(TokenType.caret);
      case $lessThan:
        return _makeToken(_match($equal) ? TokenType.lessThanEqual : TokenType.lessThan);
      case $greaterThan:
        return _makeToken(_match($equal) ? TokenType.greaterThanEqual : TokenType.greaterThan);
      case $doubleQuote:
        return _string();

      case $space:
      case $cr:
      case $tab:
      case $lf:
      // ignore whitespace
        break;
    }
    return _errorToken('Unexpected character.');
  }

  Token _makeToken(TokenType type) {
    return Token(type: type, span: _currentSpan);
  }

  Token _errorToken(String message) {
    return ErrorToken(span: _currentSpan, message: message);
  }


  void _skipWhitespace() {
    for(;;) {
      final char = _peek();
      switch (char) {
        case $space:
        case $cr:
        case $tab:
        case $lf:
          _advance();
          break;
        // Comment
        case $hash:
           while (!_isAtEnd && _peek() != $lf) {
             _advance();
           }
          break;
        default:
          return;
      }
    }
  }

  Token _identifier() {
    while (isAlpha(_peek()) || isDigit(_peek())) {
      _advance();
    }
    return Token(type: TokenType.identifier, span: _currentSpan);
  }

  Token _string() {
    while (_peek() != $doubleQuote) {
      if (_isAtEnd) {
        return _errorToken('Unterminated string.');
      }
      _advance();
    }
    // consume the closing double quote
    _advance();
    return Token(type: TokenType.string, span: _currentSpan);
  }

  Token _number(int firstChar) {
    String consumeDigits() {
      final buffer = StringBuffer();
      while (!_isAtEnd && isDigit(_peek())) {
        buffer.writeCharCode(_nextChar());
      }
      return buffer.toString();
    }

    final beforeDecimal = String.fromCharCode(firstChar) + consumeDigits();
    String? afterDecimal;
    bool hasDecimal = false;

    if (_peek() == $dot && !_isAtEnd) {
      hasDecimal = true;
      _advance(); // consume dot

      final digits = consumeDigits();
      if (digits.isNotEmpty) {
        afterDecimal = digits;
      }
    }
    // tokens.add(NumericToken(_currentSpan,
    //     beforeDecimal: beforeDecimal,
    //     hasDecimal: hasDecimal,
    //     afterDecimal: afterDecimal));
    return NumericToken(_currentSpan,
        beforeDecimal: beforeDecimal,
        hasDecimal: hasDecimal,
        afterDecimal: afterDecimal);
  }

  bool _match(int expected) {
    if (_isAtEnd) return false;
    if (_charCodes[_current] != expected) return false;
    _advance();
    return true;
  }

  int _nextChar() {
    _advance();
    return _charCodes[_current - 1];
  }

  void _advance() => _current++;

  int _peek() {
    if (_isAtEnd) return 0;
    return _charCodes[_current];
  }

  bool get _isAtEnd => _current >= source.length;

  FileSpan get _currentSpan => _file.span(_start, _current);

  SourceLocation get _currentLocation => _file.location(_current);
}

/// Returns true if [charCode] is a digit.
bool isDigit(int charCode) {
  return $0 <= charCode && charCode <= $9;
}

bool isAlpha(int charCode) {
  return $a <= charCode && charCode <= $z || $A <= charCode && charCode <= $Z ||
      charCode == $underscore;
}

/// Returns true if [charCode] is a valid identifier character.
bool isName(int charCode) {
  return $a <= charCode && charCode <= $z ||
      $A <= charCode && charCode <= $Z ||
      charCode == $underscore;
}
