import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:lextax_analysis/model/token.dart';

class CsvHandler {
  // Singleton pattern
  static final CsvHandler _csvHandler = CsvHandler._internal();
  factory CsvHandler() {
    return _csvHandler;
  }
  CsvHandler._internal();

  List<List<String>> tokensToList(List<Token> tokens) {
    List<List<String>> tokenList = [['Lexeme', 'Token']];
    for (Token token in tokens) {
      tokenList.add([token.value, token.type]);
    }
    return tokenList;
  }

  String listToCsv(List<List<String>> tokenList) {
    return const ListToCsvConverter().convert(tokenList);
  }

  downloadCsv(String csv) async {
    Uint8List csvBytes = Uint8List.fromList(utf8.encode(csv));

    await FileSaver.instance.saveFile(
      name: 'symbol_table_${DateTime.now()}',
      bytes: csvBytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }
}
