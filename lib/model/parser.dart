import 'package:lextax_analysis/model/token.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;

  Parser(this.tokens);

  Token get _peek => tokens[_current];
  Token get _previous => tokens[_current - 1];

  bool _isAtEnd() => _current >= tokens.length;

  bool _match(List<String> types) {
    for (var type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(String type) {
    if (_isAtEnd()) {
      return false;
    }
    return _peek.type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) {
      _current++;
    }
    return _previous;
  }

  Token _consume(String type, String message) {
    if (_check(type)) {
      return _advance();
    }
    throw Exception('Error at ${_peek.type}: $message');
  }

  void parse() {
    try {
      _program();
      print('Parsing completed');
    } catch (e) {
      print('Parsing failed: $e');
    }
  }

  void _program() {
    _mainFunction();
  }

  void _mainFunction() {
    //_consume('GUI', 'Expected "gui"');
    //_consume('MAIN', 'Expected "main"');
    //_consume('LEFT_PAREN', 'Expected "("');
    //_consume('RIGHT_PAREN', 'Expected ")"');
    //_consume('LEFT_BRACE', 'Expected "{"');
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      _statement();
    }
    //_consume('RIGHT_BRACE', 'Expected "}"');
  }

  void _statement() {
    if (_check('TYPE')) {
      _variableDeclaration();
      _consume('SEMICOLON', 'Expected ";"');
    } else if (_check('IDENTIFIER')) {
      _assignment();
      _consume('SEMICOLON', 'Expected ";"');
    } else if (_check('PRINT')) {
      _printStatement();
    } else if (_check('IF')) {
      _ifStatement();
    } else if (_check('FOR')) {
      _forLoop();
    } else if (_check('WHILE')) {
      _whileLoop();
    } else if (_check('RETURN')) {
      _returnGui();
    } else {
      throw Exception('Unexpected token: ${_peek.value}');
    }
  }

  void _variableDeclaration() {
    _advance();
    _consume('IDENTIFIER', 'Expected IDENTIFIER');
    if (_check('SEMICOLON')) {
      return;
    } else if (_check('EQUAL')) {
      _consume('EQUAL', 'Expected "="');
      if (_check('INPUT')) {
        _inputStatement();
        return;
      }
      _expression();
    } else {
      throw Exception('Expected "=" or ";"');
    }
  }

  void _assignment() {
    _consume('IDENTIFIER', 'Expected variable name');
    if (_check('INC_DEC_OP')) {
      _advance();
      return;
    } else if (_check('EQUAL')) {
      if (_check('INPUT')) {
        _inputStatement();
        return;
      }
      _advance();
      _expression();
    } else if (_check('ASSIGN_OP')) {
      _assignOps();
      if (_check('INPUT')) {
        _inputStatement();
        return;
      }
      _expression();
    } else {
      throw Exception('Unexpected token: ${_peek.value}');
    }
  }

  void _printStatement() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');
  }

  void _inputStatement() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('RIGHT_PAREN', 'Expected ")"');
  }

  void _assignOps() {
    _consume('ASSIGN_OP', 'Expected assignment operator');
  }

  void _expression() {
    _orExpr();
  }

  void _orExpr() {
    _andExpr();
    while (_match(['OR_OP'])) {
      _andExpr();
    }
  }

  void _andExpr() {
    _equExpr();
    while (_match(['AND_OP'])) {
      _equExpr();
    }
  }

  void _equExpr() {
    _relExpr();
    while (_match(['EQU_OP'])) {
      _relExpr();
    }
  }

  void _relExpr() {
    _addExpr();
    while (_match(['REL_OP'])) {
      _addExpr();
    }
  }

  void _addExpr() {
    _mulExpr();
    while (_match(['PLUS', 'MINUS'])) {
      _mulExpr();
    }
  }

  void _mulExpr() {
    _unaExpr();
    while (_match(['MUL_OP'])) {
      _unaExpr();
    }
  }

  void _unaExpr() {
    if (_match(['MINUS', 'UNA_OP', 'INC_DEC_OP'])) {
      _unaExpr();
    } else {
      _priExpr();
    }
  }

  void _priExpr() {
    if (_match(['NUMBER', 'REAL', 'STRING', 'BOOL', 'IDENTIFIER'])) {
      return;
    } else if (_match(['LEFT_BRACKET'])) {
      if (_check('RIGHT_BRACKET')) {
        _advance();
        return;
      } else {
        _expression();
        while (!_check('RIGHT_BRACKET') && !_isAtEnd()) {
          _consume('COMMA', 'Expected ","');
          _expression();
        }
        _consume('RIGHT_BRACKET', 'Expected "]"');
      }
    } else if (_match(['LEFT_PAREN'])) {
      _expression();
      _consume('RIGHT_PAREN', 'Expected ")"');
    } else {
      throw Exception('Invalid primary expression');
    }
  }

  void _ifStatement() {
    _consume('IF', 'Expected "if"');
    _consume('LEFT_PAREN', 'Expected "("');
    _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      _statement();
    }
    _consume('RIGHT_BRACE', 'Expected "}"');
    if (_check('ELSE')) {
      _advance();
      if (_check('IF')) {
        _ifStatement();
        return;
      }
      _consume('LEFT_BRACE', 'Expected "{"');
      while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
        _statement();
      }
      _consume('RIGHT_BRACE', 'Expected "}"');
    }
  }

  void _forLoop() {
    _consume('FOR', 'Expected "for"');
    _consume('LEFT_PAREN', 'Expected "("');
    if (_check('TYPE')) {
      _variableDeclaration();
    } else if (_check('IDENTIFIER')) {
      _assignment();
    }
    _consume('SEMICOLON', 'Expected ";"');
    _expression();
    _consume('SEMICOLON', 'Expected ";"');
    _assignment();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      _statement();
    }
    _consume('RIGHT_BRACE', 'Expected "}"');
  }

  void _whileLoop() {
    _consume('WHILE', 'Expected "while"');
    _consume('LEFT_PAREN', 'Expected "("');
    _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      _statement();
    }
    _consume('RIGHT_BRACE', 'Expected "}"');
  }

  void _returnGui() {
    _consume('RETURN', 'Expected return');
    _consume('GUI', 'Expected gui');
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('CONTENTS', 'Expected "contents"');
    _consume('COLON', 'Expected ":"');
    _consume('LEFT_BRACKET', 'Expected "["');
    _consume('RIGHT_BRACKET', 'Expected "]"');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');
  }

  void _argumentList() {
    _expression();
    while (_check('COMMA')) {
      _advance();
      _expression();
    }
  }
}
