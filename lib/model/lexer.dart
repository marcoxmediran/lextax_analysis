import 'package:sanitize_html/sanitize_html.dart' show sanitizeHtml;
import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/model/token_type.dart';
import 'package:lextax_analysis/model/symbol_definition.dart';
import 'package:lextax_analysis/model/keyword_definition.dart';
import 'package:lextax_analysis/model/operator_definition.dart';

class Lexer {
  final String input;
  int _cursor = 0;
  final tokens = <Token>[];

  Lexer(this.input);

  bool _hasMore() => _cursor < input.length;

  void tokenize() {
    tokens.clear();
    while (_hasMore()) {
      Token? token = _nextToken();

      if (token.type == 'INVALID_TOKEN') {
        tokens.add(token);
        return;
      } else if (token.type == 'WHITESPACE') {
        continue;
      } else {
        if (token.type == 'STRING' && tokens.length >= 4) {
          int latestIndex = tokens.length - 1;
          if (tokens[latestIndex].type == 'COLON' &&
              tokens[latestIndex - 1].type == 'VALUE_RESWORD' &&
              tokens[latestIndex - 2].type == 'LEFT_PAREN' &&
              tokens[latestIndex - 3].type == 'PURIFY_DEV_RESWORD') {
            token.value = sanitizeHtml(token.value);
          }
        }
        tokens.add(token);
      }
    }
  }

  Token _nextToken() {
    if (!_hasMore()) return Token('', 'EOF', _cursor, 0);

    final start = _cursor;
    final char = input[_cursor++];

    // Match for whitespace
    if (_isWhitespace(char)) {
      while (_hasMore() && _isWhitespace(input[_cursor])) {
        _cursor++;
      }
      return Token(input.substring(start, _cursor), 'WHITESPACE', start,
          _cursor - start);
    }

    // Match for comments
    if (char == '/' && _hasMore()) {
      if (input[_cursor] == '/') {
        while (_hasMore() && input[_cursor] != '\n') {
          _cursor++;
        }
        return Token(
            input.substring(start, _cursor), 'COMMENT', start, _cursor - start);
      } else if (input[_cursor] == '*') {
        _cursor++; // Skip '*'
        while (_hasMore() &&
            !(input[_cursor] == '*' &&
                _cursor + 1 < input.length &&
                input[_cursor + 1] == '/')) {
          _cursor++;
        }
        _cursor += 2; // Skip '*/'
        return Token(
            input.substring(start, _cursor), 'COMMENT', start, _cursor - start);
      }
    }

    // Match for strings
    if (char == '"' || char == "'") {
      final quote = char;
      while (_hasMore()) {
        final nextChar = input[_cursor];

        // Handle escaped characters
        if (nextChar == '\\' && _cursor + 1 < input.length) {
          _cursor++; // Skip the backslash
          _cursor++; // Skip the escaped character
        } else if (nextChar == quote) {
          _cursor++; // Skip closing quote
          break;
        } else {
          _cursor++;
        }
      }

      // Return token for the string
      final substr = input.substring(start, _cursor);
      return Token(substr, substr.endsWith(quote) ? 'STRING' : 'INVALID_TOKEN',
          start, _cursor - start);
    }

    // Match for numbers
    if (_isDigit(char)) {
      while (
          _hasMore() && (_isDigit(input[_cursor]) || input[_cursor] == '_')) {
        _cursor++;
      }
      if (_hasMore() && input[_cursor] == '.') {
        _cursor++;
        while (
            _hasMore() && (_isDigit(input[_cursor]) || input[_cursor] == '_')) {
          _cursor++;
        }
        return Token(
            input.substring(start, _cursor), 'REAL', start, _cursor - start);
      }
      return Token(
          input.substring(start, _cursor), 'NUMBER', start, _cursor - start);
    }

    // Match for words/identifiers
    if (_isLetter(char)) {
      while (_hasMore() &&
          (_isLetterOrDigit(input[_cursor]) || input[_cursor] == '_')) {
        _cursor++;
      }
      final value = input.substring(start, _cursor);
      final type =
          keywordSet.containsKey(value) ? keywordSet[value]! : 'IDENTIFIER';
      return Token(value, type, start, _cursor - start);
    }

    // Match for operators
    if (_isOperatorChar(char)) {
      final nextChar = _hasMore() ? input[_cursor] : '';
      final twoCharOp = '$char$nextChar';
      if (operatorSet.containsKey(twoCharOp)) {
        _cursor++;
        return Token(twoCharOp, operatorSet[twoCharOp]!, start, 2);
      }
      return Token(char, operatorSet[char] ?? 'OPERATOR', start, 1);
    }

    // Match for symbols
    if (symbolSet.containsKey(char)) {
      return Token(char, symbolSet[char]!, start, 1);
    }

    // Invalid token
    return Token(
        input.substring(start), 'INVALID_TOKEN', start, input.length - start);
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;
  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57; // '0' to '9'
  bool _isLetter(String char) =>
      (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) || // 'A' to 'Z'
      (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122); // 'a' to 'z'
  bool _isLetterOrDigit(String char) => _isLetter(char) || _isDigit(char);
  bool _isOperatorChar(String char) => '+-*/%^=<>!&|'.contains(char);
}
