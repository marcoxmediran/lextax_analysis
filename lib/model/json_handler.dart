import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:lextax_analysis/model/ast.dart';

class JsonHandler {
  // Singleton pattern
  static final JsonHandler _jsonHandler = JsonHandler._internal();
  factory JsonHandler() {
    return _jsonHandler;
  }
  JsonHandler._internal();

  downloadJson(ProgramNode program) async {
    const encoder = JsonEncoder.withIndent('  ');

    await FileSaver.instance.saveFile(
      name: 'parse_tree_${DateTime.now()}',
      bytes: utf8.encode(encoder.convert(program.toJson())),
      ext: 'json',
      mimeType: MimeType.json,
    );
  }
}
