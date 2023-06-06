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
    if (_isAtEnd) {
      return Token(type: TokenType.eof, span: _file.span(_file.length));
    }

    final char = _nextChar();

    if (char.isAlphanumeric) return _identifier();

    if (char.isDigit) {
      return _number(char);
    }

    return switch (char) {
      $openParen => _makeToken(TokenType.leftParen),
      $closeParen => _makeToken(TokenType.rightParen),
      $comma => _makeToken(TokenType.comma),
      $minus => _makeToken(TokenType.minus),
      $plus => _makeToken(TokenType.plus),
      $slash => _makeToken(TokenType.slash),
      $asterisk => _makeToken(TokenType.star),
      $tilde => _makeToken(TokenType.tilde),
      $equal => _makeToken(TokenType.equal),
      $exclamation => _makeToken(TokenType.bang),
      $question => _makeToken(TokenType.question),
      $colon => _makeToken(TokenType.colon),
      $caret => _makeToken(TokenType.caret),
      $lessThan when _match($equal) => _makeToken(TokenType.lessThanEqual),
      $lessThan => _makeToken(TokenType.lessThan),
      $greaterThan when _match($equal) =>
        _makeToken(TokenType.greaterThanEqual),
      $greaterThan => _makeToken(TokenType.greaterThan),
      $doubleQuote => _string(),
      $space || $cr || $tab || $lf => _errorToken('Unexpected whitespace.'),
      _ => _errorToken('Unexpected character.'),
    };
  }

  Token _makeToken(TokenType type) {
    return Token(type: type, span: _currentSpan);
  }

  Token _errorToken(String message) {
    return ErrorToken(span: _currentSpan, message: message);
  }

  void _skipWhitespace() {
    for (;;) {
      final char = _peek();
      switch (char) {
        case $space:
        case $cr:
        case $tab:
        case $lf:
          _advance();
        // Comment
        case $hash:
          while (!_isAtEnd && _peek() != $lf) {
            _advance();
          }
        default:
          return;
      }
    }
  }

  Token _identifier() {
    while (_peek().isAlphanumeric || _peek().isDigit) {
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
      while (!_isAtEnd && _peek().isDigit) {
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

extension on int {
  bool get isDigit => $0 <= this && this <= $9;
  bool get isAlphanumeric =>
      $a <= this && this <= $z ||
      $A <= this && this <= $Z ||
      this == $underscore;
  bool get isIdentifier =>
      $a <= this && this <= $z ||
      $A <= this && this <= $Z ||
      this == $underscore;
}
