class Token {
  String value;
  String type;
  int line;
  int start;
  int length;

  Token(this.value, this.type, this.line, this.start, this.length);

  @override
  String toString() {
    return "Token(value: $value, type: $type, line: $line, start: $start, length: $length)";
  }
}
