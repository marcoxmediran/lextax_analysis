abstract class ASTNode {
  Map<String, dynamic> toJson();
}

abstract class StatementNode extends ASTNode {}

abstract class ExpressionNode extends ASTNode {}

abstract class GUIComponent extends ASTNode {}

class ProgramNode extends ASTNode {
  final List<StatementNode> statements;
  ProgramNode(this.statements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Program',
      'statements': statements.map((stmnt) => stmnt.toJson()).toList(),
    };
  }
}

class VariableDeclarationNode extends StatementNode {
  final String type;
  final String identifier;
  final ExpressionNode? initializer;
  VariableDeclarationNode(this.type, this.identifier, this.initializer);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'VariableDeclaration',
      'varType': type,
      'identifier': identifier,
      'initializer': initializer?.toJson(),
    };
  }
}

class IssNode extends StatementNode {
  IssNode();

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'InputSecureStorageNode',
    };
  }
}

class AssignmentNode extends StatementNode {
  final String identifier;
  final String operator;
  final ExpressionNode value;
  AssignmentNode(this.identifier, this.operator, this.value);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AssignmentStatement',
      'identifier': identifier,
      'operator': operator,
      'value': value,
    };
  }
}

class PrintNode extends StatementNode {
  final ExpressionNode expression;
  PrintNode(this.expression);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'PrintNode',
      'expression': expression,
    };
  }
}

class InputNode extends ExpressionNode {
  InputNode();
  @override
  Map<String, dynamic> toJson() {
    return {'type': 'InputNode'};
  }
}

class LiteralNode extends ExpressionNode {
  final dynamic value;
  LiteralNode(this.value);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Literal',
      'value': value,
    };
  }
}

class IdentifierNode extends ExpressionNode {
  final String name;
  IdentifierNode(this.name);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Identifier',
      'name': name,
    };
  }
}

class PurifyDevNode extends ExpressionNode {
  final String value;
  PurifyDevNode(this.value);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'PurifyDevNode',
      'value': value,
    };
  }
}

class IfStatementNode extends StatementNode {
  final ExpressionNode condition;
  final List<StatementNode> thenBranch;
  final List<ElseIfStatementNode> elseIfBranches;
  final List<StatementNode> elseBranch;
  IfStatementNode(
      this.condition, this.thenBranch, this.elseIfBranches, this.elseBranch);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'IfStatement',
      'condition': condition,
      'thenBranch': thenBranch.map((stmnt) => stmnt.toJson()).toList(),
      'elseIfBranches': elseIfBranches.isNotEmpty
          ? elseIfBranches.map((stmnt) => stmnt.toJson()).toList()
          : null,
      'elseBranch': elseBranch.isNotEmpty
          ? elseBranch.map((stmnt) => stmnt.toJson()).toList()
          : null
    };
  }
}

class ElseIfStatementNode extends StatementNode {
  final ExpressionNode condition;
  final List<StatementNode> statements;
  ElseIfStatementNode(this.condition, this.statements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ElseIfState',
      'condition': condition,
      'statements': statements.map((stmnt) => stmnt.toJson()).toList(),
    };
  }
}

class ForLoopNode extends StatementNode {
  final VariableDeclarationNode initializer;
  final ExpressionNode condition;
  final ExpressionNode action;
  final List<StatementNode> statements;
  ForLoopNode(this.initializer, this.condition, this.action, this.statements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ForLoop',
      'initializer': initializer,
      'condition': condition,
      'action': action,
      'statements': statements.map((stmnt) => stmnt.toJson()).toList()
    };
  }
}

class WhileLoopNode extends StatementNode {
  final ExpressionNode condition;
  final List<StatementNode> statements;
  WhileLoopNode(this.condition, this.statements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'WhileLoop',
      'condition': condition,
      'statements': statements.map((action) => action.toJson()).toList(),
    };
  }
}

class BinaryExpressionNode extends ExpressionNode {
  final ExpressionNode left;
  final String operator;
  final ExpressionNode right;
  BinaryExpressionNode(this.left, this.operator, this.right);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'BinaryExpression',
      'operator': operator,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}

class ArrayLiteral extends ExpressionNode {
  final List<ExpressionNode> elements;
  ArrayLiteral(this.elements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ArrayLiteral',
      'elements': elements.map((child) => child.toJson()).toList(),
    };
  }
}

class RowComponent extends GUIComponent {
  final List<GUIComponent> children;

  RowComponent(this.children);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Row',
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

class ColumnComponent extends GUIComponent {
  final List<GUIComponent> children;

  ColumnComponent(this.children);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Column',
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

class ButtonComponent extends GUIComponent {
  final String label;
  final List<ASTNode> actionStatements;

  ButtonComponent(this.label, this.actionStatements);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Button',
      'label': label,
      'actions': actionStatements.map((stmt) => stmt.toJson()).toList(),
    };
  }
}

class TextComponent extends GUIComponent {
  final String label;

  TextComponent(this.label);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Text',
      'label': label,
    };
  }
}

class FieldComponent extends GUIComponent {
  final String value;

  FieldComponent(this.value);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Field',
      'identifier': value,
    };
  }
}

class ReturnGUI extends StatementNode {
  final List<GUIComponent> components;

  ReturnGUI(this.components);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ReturnGUI',
      'components': components.map((comp) => comp.toJson()).toList(),
    };
  }
}
