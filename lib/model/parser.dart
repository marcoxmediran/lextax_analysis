import 'package:lextax_analysis/globals.dart';
import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/model/ast.dart';

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
    throw Exception(
        '[${_previous.line}:${_previous.col}] ERROR: $message after "${_previous.value}".');
  }

  ProgramNode? parse() {
    try {
      ProgramNode program = _program();
      Globals.snackBarNotif('Parsing completed. No Errors generated.');
      return program;
    } catch (e) {
      Globals.snackBarNotif(e.toString().substring(10));
    }
    return null;
  }

  ProgramNode _program() {
    _consume('GUI', 'Expected "gui"');
    _consume('MAIN', 'Expected "main"');
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    List<StatementNode> statements = _parseBlock();
    return ProgramNode(statements);
  }

  StatementNode _statement() {
    if (_check('TYPE')) {
      return _variableDeclaration();
    } else if (_check('IDENTIFIER')) {
      return _assignment(isInside: false);
    } else if (_check('PRINT')) {
      return _printStatement();
    } else if (_check('IF')) {
      return _ifStatement();
    } else if (_check('FOR')) {
      return _forLoop();
    } else if (_check('WHILE')) {
      return _whileLoop();
    } else if (_check('ISS')) {
      return _issStatement();
    } else if (_check('RETURN')) {
      return _returnGui();
    } else {
      throw Exception(
          '[${_peek.line}:${_peek.col}] ERROR: Unexpected token: ${_peek.value}');
    }
  }

  VariableDeclarationNode _variableDeclaration() {
    String type = _advance().value;
    Token identifier = _consume('IDENTIFIER', 'Expected variable name');
    ExpressionNode? initializer;
    if (_match(['EQUAL'])) {
      if (_match(['INPUT'])) {
        return VariableDeclarationNode(
            type, identifier.value, _inputStatement());
      }
      initializer = _expression();
    }
    _consume('SEMICOLON', 'Expected ";"');
    return VariableDeclarationNode(type, identifier.value, initializer);
  }

  AssignmentNode _assignment({required bool isInside}) {
    Token identifier = _consume('IDENTIFIER', 'Expected variable name');
    String operator = '=';
    if (_check('EQUAL')) {
      _advance();
    } else {
      _assignOps();
      operator = _previous.value;
    }
    if (_match(['INPUT'])) {
      return AssignmentNode(identifier.value, operator, _inputStatement());
    }
    ExpressionNode value = _expression();
    if (!isInside) {
      _consume('SEMICOLON', 'Expected ";"');
    }
    return AssignmentNode(identifier.value, operator, value);
  }

  PrintNode _printStatement() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    ExpressionNode expr = _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');
    return PrintNode(expr);
  }

  InputNode _inputStatement() {
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');
    return InputNode();
  }

  IssNode _issStatement() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');
    return IssNode();
  }

  void _assignOps() {
    _consume('ASSIGN_OP', 'Expected assignment operator');
  }

  ExpressionNode _expression() {
    ExpressionNode expr = _andExpr();
    while (_match(['OR_OP'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _andExpr());
    }
    return expr;
  }

  ExpressionNode _andExpr() {
    ExpressionNode expr = _equExpr();
    while (_match(['AND_OP'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _equExpr());
    }
    return expr;
  }

  ExpressionNode _equExpr() {
    ExpressionNode expr = _relExpr();
    while (_match(['EQU_OP'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _relExpr());
    }
    return expr;
  }

  ExpressionNode _relExpr() {
    ExpressionNode expr = _addExpr();
    while (_match(['REL_OP'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _addExpr());
    }
    return expr;
  }

  ExpressionNode _addExpr() {
    ExpressionNode expr = _mulExpr();
    while (_match(['PLUS', 'MINUS'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _mulExpr());
    }
    return expr;
  }

  ExpressionNode _mulExpr() {
    ExpressionNode expr = _unaExpr();
    while (_match(['MUL_OP'])) {
      expr = BinaryExpressionNode(expr, _previous.value, _unaExpr());
    }
    return expr;
  }

  ExpressionNode _unaExpr() {
    if (_match(['MINUS', 'UNA_OP', 'INC_DEC_OP'])) {
      return BinaryExpressionNode(LiteralNode(0), _previous.value, _unaExpr());
    } else {
      return _priExpr();
    }
  }

  ExpressionNode _priExpr() {
    if (_match(['NUMBER', 'REAL', 'STRING', 'BOOL'])) {
      return LiteralNode(_previous.value);
    } else if (_match(['IDENTIFIER'])) {
      String identifier = _previous.value;
      if (_match(['INC_DEC_OP'])) {
        return BinaryExpressionNode(
            IdentifierNode(identifier), _previous.value, LiteralNode(0));
      }
      return IdentifierNode(identifier);
    } else if (_match(['LEFT_BRACKET'])) {
      List<ExpressionNode> elements = [];
      elements.add(_expression());
      while (!_check('RIGHT_BRACKET') && !_isAtEnd()) {
        _consume('COMMA', 'Expected ","');
        elements.add(_expression());
      }
      _consume(('RIGHT_BRACKET'), 'Expected ")"');
      return ArrayLiteral(elements);
    } else if (_match(['LEFT_PAREN'])) {
      ExpressionNode expr = _expression();
      _consume(('RIGHT_PAREN'), 'Expected ")"');
      return expr;
    } else if (_match(['PURIFY_DEV'])) {
      return _purifyDevStatement();
    } else {
      throw Exception('[${_peek.line}:${_peek.col}] ERROR: Invalid expresson');
    }
  }

  IfStatementNode _ifStatement() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    ExpressionNode condition = _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');

    List<ElseIfStatementNode> elseIfBranches = [];
    List<StatementNode> thenBranch = _parseBlock();
    while (_match(['ELSE']) && _check('IF')) {
      _advance();
      _consume('LEFT_PAREN', 'Expected "("');
      ExpressionNode elseIfCondition = _expression();
      _consume('RIGHT_PAREN', 'Expected ")"');
      _consume('LEFT_BRACE', 'Expected "{"');

      List<StatementNode> elseIfBody = _parseBlock();
      elseIfBranches.add(ElseIfStatementNode(elseIfCondition, elseIfBody));
    }

    List<StatementNode> elseBranch = [];
    if (_previous.type == 'ELSE') {
      _consume('LEFT_BRACE', 'Expected "{"');
      elseBranch = _parseBlock();
    }

    return IfStatementNode(condition, thenBranch, elseIfBranches, elseBranch);
  }

  ForLoopNode _forLoop() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    VariableDeclarationNode initializer = _variableDeclaration();
    ExpressionNode condition = _expression();
    _consume('SEMICOLON', 'Expected ";"');
    ExpressionNode action = _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    List<StatementNode> statements = _parseBlock();

    return ForLoopNode(initializer, condition, action, statements);
  }

  WhileLoopNode _whileLoop() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    ExpressionNode condition = _expression();
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    List<StatementNode> statements = _parseBlock();

    return WhileLoopNode(condition, statements);
  }

  PurifyDevNode _purifyDevStatement() {
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('VALUE', 'Expected "value"');
    _consume('COLON', 'Expected ":"');
    if (!_match(['IDENTIFIER', 'STRING'])) {
      throw Exception('[${_peek.line}:${_peek.col}] ERROR: purify_dev expects identifier or string as value');
    }
    String value = _previous.value;
    _consume('RIGHT_PAREN', 'Expected ")"');
    return PurifyDevNode(value);
  }

  ReturnGUI _returnGui() {
    _advance();
    _consume('GUI', 'Expected gui');
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('CONTENTS', 'Expected "contents"');
    _consume('COLON', 'Expected ":"');
    _consume('LEFT_BRACKET', 'Expected "["');
    List<GUIComponent> components = [];
    components.add(_component());
    while (!_check('RIGHT_BRACKET') && !_isAtEnd()) {
      _consume('COMMA', 'Exected ","');
      components.add(_component());
    }
    _consume('RIGHT_BRACKET', 'Expected "]"');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('SEMICOLON', 'Expected ";"');

    return ReturnGUI(components);
  }

  GUIComponent _component() {
    if (_match(['ROW'])) {
      return _rowOrCol(isRow: true);
    } else if (_match(['COLUMN'])) {
      return _rowOrCol(isRow: false);
    } else if (_check('BUTTON')) {
      return _button();
    } else if (_check('FIELD')) {
      return _field();
    } else if (_check('TEXT')) {
      return _text();
    } else {
      throw Exception(
          'Unrecognized GUI Component at line[${_peek.line}:${_peek.col}] "${_peek.value}"');
    }
  }

  GUIComponent _rowOrCol({required bool isRow}) {
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('CONTENTS', 'Expected "contents"');
    _consume('COLON', 'Expected ":"');
    _consume('LEFT_BRACKET', 'Expected "["');
    List<GUIComponent> children = [];
    children.add(_component());
    while (!_check('RIGHT_BRACKET') && !_isAtEnd()) {
      _consume('COMMA', 'Expected ","');
      children.add(_component());
    }
    _consume('RIGHT_BRACKET', 'Expected "]"');
    _consume('RIGHT_PAREN', 'Expected ")"');

    return isRow ? RowComponent(children) : ColumnComponent(children);
  }

  ButtonComponent _button() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('ACTION', 'Expected "action"');
    _consume('COLON', 'Expected ":"');
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('RIGHT_PAREN', 'Expected ")"');
    _consume('LEFT_BRACE', 'Expected "{"');
    List<StatementNode> actions = _parseBlock();
    _consume('COMMA', 'Expected ","');
    _consume('LABEL', 'Expected "label"');
    _consume('COLON', 'Expected ":"');
    if (!_match(['STRING', 'IDENTIFIER'])) {
      throw Exception(
          '[${_peek.line}:${_peek.col}] ERROR: Expected STRING or IDENTIFIER');
    }
    String label = _previous.value;
    _consume('RIGHT_PAREN', 'Expected ")"');

    return ButtonComponent(label, actions);
  }

  FieldComponent _field() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('VALUE', 'Expected "value"');
    _consume('COLON', 'Expected ":"');
    _consume('IDENTIFIER', 'Expected IDENTIFIER');
    String value = _previous.value;
    _consume('RIGHT_PAREN', 'Expected ")"');

    return FieldComponent(value);
  }

  TextComponent _text() {
    _advance();
    _consume('LEFT_PAREN', 'Expected "("');
    _consume('LABEL', 'Expected "label"');
    _consume('COLON', 'Expected ":"');
    if (!_match(['STRING', 'IDENTIFIER'])) {
      throw Exception('Expected STRING or IDENTIFIER');
    }
    String label = _previous.value;
    _consume('RIGHT_PAREN', 'Expected ")"');

    return TextComponent(label);
  }

  List<StatementNode> _parseBlock() {
    List<StatementNode> statements = [];
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      statements.add(_statement());
    }
    _consume('RIGHT_BRACE', 'Expected "}"');
    return statements;
  }
}
