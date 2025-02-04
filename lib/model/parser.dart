import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/model/ast.dart';

class Parser {
  final List<Token> tokens;
  final List<String> _errors = [];
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

    if (!_isAtEnd() &&
        (_errors.isEmpty || !_errors.last.contains(_lineDetails()))) {
      _errors.add(
          'ERROR at ${_lineDetails()}: $message after "${_previous.value}"');
    }

    return _previous;
  }

  void _synchronize() {
    _advance();
    const List<String> syncTokens = [
      'TYPE',
      'IDENTIFIER',
      'PRINT',
      'IF',
      'FOR',
      'WHILE',
      'ISS',
      'RETURN',
      'ROW',
      'COLUMN',
      'BUTTON',
      'FIELD',
      'TEXT',
      'SEMICOLON',
      'RIGHT_BRACKET',
      'RIGHT_PAREN',
    ];

    while (!_isAtEnd()) {
      if (syncTokens.contains(_previous.type)) {
        return;
      }

      _advance();
    }
  }

  String _lineDetails() {
    return '[${_previous.line}:${_previous.col}]';
  }

  String _formatError(String e) {
    return e.substring(10);
  }

  void _addError(String e) {
    _errors.add(_formatError(e).trim());
    _synchronize();
  }

  ProgramNode? parse() {
    ProgramNode? program;
    try {
      program = _program();
    } catch (e) {
      _errors.add(_formatError(e.toString()));
    }
    return program;
  }

  String getLogs() {
    String message = '';
    if (_errors.isEmpty) {
      message += 'Parsing completed. No errors generated';
      return message;
    } else {
      message += 'Parsing completed. Generated ${_errors.length} error(s):';
      for (String error in _errors) {
        message += '\n$error';
      }
      return message;
    }
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
    try {
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
            'ERROR at ${_lineDetails()}: Unexpected token: ${_peek.value}');
      }
    } catch (e) {
      _addError(e.toString());
      return _statement();
    }
  }

  VariableDeclarationNode _variableDeclaration() {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return VariableDeclarationNode('UNKNOWN', 'UNKNOWN', null);
    }
  }

  AssignmentNode _assignment({required bool isInside}) {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return AssignmentNode('UNKNOWN', 'UNKNOWN', LiteralNode(0));
    }
  }

  PrintNode _printStatement() {
    try {
      _advance();
      _consume('LEFT_PAREN', 'Expected "("');
      ExpressionNode expr = _expression();
      _consume('RIGHT_PAREN', 'Expected ")"');
      _consume('SEMICOLON', 'Expected ";"');
      return PrintNode(expr);
    } catch (e) {
      _addError(e.toString());
      return PrintNode(LiteralNode(0));
    }
  }

  InputNode _inputStatement() {
    try {
      _consume('LEFT_PAREN', 'Expected "("');
      _consume('RIGHT_PAREN', 'Expected ")"');
      _consume('SEMICOLON', 'Expected ";"');
      return InputNode();
    } catch (e) {
      _addError(e.toString());
      return InputNode();
    }
  }

  IssNode _issStatement() {
    try {
      _advance();
      _consume('LEFT_PAREN', 'Expected "("');
      _consume('RIGHT_PAREN', 'Expected ")"');
      _consume('SEMICOLON', 'Expected ";"');
      return IssNode();
    } catch (e) {
      _addError(e.toString());
      return IssNode();
    }
  }

  void _assignOps() {
    _consume('ASSIGN_OP', 'Expected assignment operator');
  }

  ExpressionNode _expression() {
    try {
      ExpressionNode expr = _andExpr();
      while (_match(['OR_OP'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _andExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _andExpr() {
    try {
      ExpressionNode expr = _equExpr();
      while (_match(['AND_OP'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _equExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _equExpr() {
    try {
      ExpressionNode expr = _relExpr();
      while (_match(['EQU_OP'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _relExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _relExpr() {
    try {
      ExpressionNode expr = _addExpr();
      while (_match(['REL_OP'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _addExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _addExpr() {
    try {
      ExpressionNode expr = _mulExpr();
      while (_match(['PLUS', 'MINUS'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _mulExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _mulExpr() {
    try {
      ExpressionNode expr = _unaExpr();
      while (_match(['MUL_OP'])) {
        expr = BinaryExpressionNode(expr, _previous.value, _unaExpr());
      }
      return expr;
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _unaExpr() {
    try {
      if (_match(['MINUS', 'UNA_OP', 'INC_DEC_OP'])) {
        return BinaryExpressionNode(
            LiteralNode(0), _previous.value, _unaExpr());
      } else {
        return _priExpr();
      }
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  ExpressionNode _priExpr() {
    try {
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
        _consume(('RIGHT_BRACKET'), 'Expected "]"');
        return ArrayLiteral(elements);
      } else if (_match(['LEFT_PAREN'])) {
        ExpressionNode expr = _expression();
        _consume(('RIGHT_PAREN'), 'Expected ")"');
        return expr;
      } else if (_match(['PURIFY_DEV'])) {
        return _purifyDevStatement();
      } else {
        throw Exception(
            'ERROR at ${_lineDetails()}: Invalid expresson after "${_previous.value}"');
      }
    } catch (e) {
      _addError(e.toString());
      return LiteralNode(0);
    }
  }

  IfStatementNode _ifStatement() {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return IfStatementNode(LiteralNode(0), [], [], []);
    }
  }

  ForLoopNode _forLoop() {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return ForLoopNode(
        VariableDeclarationNode('UNKNOWN', 'UNKNOWN', LiteralNode(0)),
        LiteralNode(false),
        LiteralNode(0),
        [],
      );
    }
  }

  WhileLoopNode _whileLoop() {
    try {
      _advance();
      _consume('LEFT_PAREN', 'Expected "("');
      ExpressionNode condition = _expression();
      _consume('RIGHT_PAREN', 'Expected ")"');
      _consume('LEFT_BRACE', 'Expected "{"');
      List<StatementNode> statements = _parseBlock();

      return WhileLoopNode(condition, statements);
    } catch (e) {
      _addError(e.toString());
      return WhileLoopNode(LiteralNode(false), []);
    }
  }

  PurifyDevNode _purifyDevStatement() {
    try {
      _consume('LEFT_PAREN', 'Expected "("');
      _consume('VALUE', 'Expected "value"');
      _consume('COLON', 'Expected ":"');
      if (!_match(['IDENTIFIER', 'STRING'])) {
        throw Exception(
            'ERROR at ${_lineDetails()}: purify_dev expects identifier or string as value');
      }
      String value = _previous.value;
      _consume('RIGHT_PAREN', 'Expected ")"');
      return PurifyDevNode(value);
    } catch (e) {
      _addError(e.toString());
      return PurifyDevNode('UNKNOWN');
    }
  }

  ReturnGUI _returnGui() {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return ReturnGUI([]);
    }
  }

  GUIComponent _component() {
    try {
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
            'ERROR at ${_lineDetails()}: Unrecognized GUI Component "${_peek.value}"');
      }
    } catch (e) {
      _addError(e.toString());
      return TextComponent('UNKNOWN');
    }
  }

  GUIComponent _rowOrCol({required bool isRow}) {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return TextComponent('UNKNOWN');
    }
  }

  ButtonComponent _button() {
    try {
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
            'ERROR at ${_lineDetails()}: Expected STRING or IDENTIFIER');
      }
      String label = _previous.value;
      _consume('RIGHT_PAREN', 'Expected ")"');

      return ButtonComponent(label, actions);
    } catch (e) {
      _addError(e.toString());
      return ButtonComponent('UNKNOWN', []);
    }
  }

  FieldComponent _field() {
    try {
      _advance();
      _consume('LEFT_PAREN', 'Expected "("');
      _consume('VALUE', 'Expected "value"');
      _consume('COLON', 'Expected ":"');
      _consume('IDENTIFIER', 'Expected IDENTIFIER');
      String value = _previous.value;
      _consume('RIGHT_PAREN', 'Expected ")"');

      return FieldComponent(value);
    } catch (e) {
      _addError(e.toString());
      return FieldComponent('UNKNOWN');
    }
  }

  TextComponent _text() {
    try {
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
    } catch (e) {
      _addError(e.toString());
      return TextComponent('UNKWOWN');
    }
  }

  List<StatementNode> _parseBlock() {
    List<StatementNode> statements = [];
    while (!_check('RIGHT_BRACE') && !_isAtEnd()) {
      try {
        statements.add(_statement());
      } catch (e) {
        _addError(e.toString());
      }
    }
    _consume('RIGHT_BRACE', 'Expected "}"');
    return statements;
  }
}
