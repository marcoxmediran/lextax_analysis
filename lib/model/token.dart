class Token {
  String value;
  String type;
  int line;
  int col;

  Token(this.value, this.type, this.line, this.col);

  @override
  String toString() {
    return "Token(value: $value, type: $type, line: $line, col: $col)";
  }
}
