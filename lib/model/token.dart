class Token {
  String value;
  String type;

  Token(this.value, this.type);

  @override
  String toString() {
    return "Token(value: $value, type: $type)";
  }
}
