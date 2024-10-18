import 'dart:collection';

import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/model/token_type.dart';

class Lexer {
  final String input;
  int _cursor = 0;
  final List<Token> tokens = [];

  // Matchers
  final List<TokenType> _tokenTypes = [
    TokenType(RegExp(r'^\s+'), 'WHITESPACE'),
    TokenType(RegExp(r'^\/\/.*'), 'COMMENT'),
    TokenType(RegExp(r'^\/\*[\s\S]*?\*\/'), 'COMMENT'),
    TokenType(RegExp(r'^"[^"]*"'), 'STRING'),
    TokenType(RegExp(r"^'[^']*'"), 'STRING'),
    TokenType(RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*'), 'WORD'),
    TokenType(RegExp(r'^\d+.\d+'), 'REAL'),
    TokenType(RegExp(r'^\d+'), 'NUMBER'),
    TokenType(RegExp(r'^[+-\\*/=<>!%]'), 'OPERATOR'),
    TokenType(RegExp(r'^[.,;(){}\[\]]'), 'SYMBOL'),
  ];
  final _keywordSet = HashSet<String>.from(['if', 'else', 'return', 'for', 'while', 'break', 'continue', 'main']);
  final _dataTypeSet = HashSet<String>.from(['int', 'float', 'string', 'char', 'bool', 'void']);
  final _booleanSet = HashSet<String>.from(['true', 'false']);

  Lexer(this.input);

  bool _hasMore() {
    return _cursor < input.length;
  }

  void tokenize() {
    tokens.clear();
    while (_hasMore()) {
      Token? token = _nextToken();

      if (token == null) {
        print('[ERROR] Unsupported token');
        return;
      } else if (token.type == "WHITESPACE" || token.type == "COMMENT") {
        continue;
      } else {
        tokens.add(token);
      }
    }
  }

  Token? _nextToken() {
    for (int i = 0; i < _tokenTypes.length; i++) {
      RegExpMatch? match =
          _tokenTypes[i].regex.firstMatch(input.substring(_cursor));

      if (match != null) {
        String? value = match[0];
        _cursor += value!.length;
        Token token = Token(value, _tokenTypes[i].type);
        if (token.type == "WORD") {
          if (_keywordSet.contains(token.value)) {
            token.type = "KEYWORD";
          } else if (_dataTypeSet.contains(token.value)) {
            token.type = "DATA_TYPE";
          } else if (_booleanSet.contains(token.value)) {
            token.type = "BOOL";
          } else {
            token.type = "IDENTIFIER";
          }
        }
        return token;
      }
    }

    return null;
  }

  void printTokens() {
    print('[INPUT]\n$input\n');
    print('[OUTPUT]');
    for (Token token in tokens) {
      print(token);
    }
  }
}
