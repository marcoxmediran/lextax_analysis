class Token {
  String value;
  String type;
  int start;
  int length;

  Token(this.value, this.type, this.start, this.length);

  @override
  String toString() {
    return "Token(value: $value, type: $type, start: $start, length: $length)";
  }
}
