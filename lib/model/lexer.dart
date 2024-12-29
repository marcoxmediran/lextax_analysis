import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/model/token_type.dart';
import 'package:lextax_analysis/model/symbol_definition.dart' '';
import 'package:lextax_analysis/model/keyword_definition.dart';
import 'package:lextax_analysis/model/operator_definition.dart';

class Lexer {
  final String input;
  int _cursor = 0;
  final tokens = <Token>[];

  // Matchers
  final _tokenTypes = <TokenType>[
    TokenType(RegExp(r'''^\s+'''), 'WHITESPACE'),
    TokenType(RegExp(r'''^\/\/.*'''), 'COMMENT'),
    TokenType(RegExp(r'''^\/\*[\s\S]*?\*\/'''), 'COMMENT'),
    TokenType(RegExp(r'''^"[^"]*"'''), 'STRING'),
    TokenType(RegExp(r"""^'[^']*'"""), 'STRING'),
    TokenType(RegExp(r'''^[a-zA-Z][a-zA-Z0-9_]*'''), 'WORD'),
    TokenType(RegExp(r'''^\d+\.\d+'''), 'REAL'),
    TokenType(RegExp(r'''^\d+'''), 'NUMBER'),
    TokenType(RegExp(r'''^(\+\+)|^(--)|^(\+\=)|^(-=)|^(\*=)|^(\/=)|^(%=)|^(>=)|^(<=)|^(==)|^(!=)|^(\|\|)|^(&&)'''), 'OPERATOR'),
    TokenType(RegExp(r'''^[\+\-\\*/=<>!%]'''), 'OPERATOR'),
    TokenType(RegExp(r'''^[.,:;(){}\[\]]'''), 'SYMBOL'),
  ];

  Lexer(this.input);

  bool _hasMore() => _cursor < input.length;

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
          if (keywordSet.containsKey(token.value)) {
            token.type = keywordSet[token.value]!;
          } else {
            token.type = "IDENTIFIER";
          }
        } else if (token.type == "OPERATOR") {
          token.type = operatorSet[token.value]!;
        } else if (token.type == "SYMBOL") {
          token.type = symbolSet[token.value]!;
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
