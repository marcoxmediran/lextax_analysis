import 'dart:math';
import 'dart:convert';
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/googlecode.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lextax_analysis/model/ast.dart';
import 'package:lextax_analysis/model/json_handler.dart';
import 'package:lextax_analysis/model/lexer.dart';
import 'package:lextax_analysis/model/parser.dart';
import 'package:lextax_analysis/model/token.dart';
import 'package:lextax_analysis/globals.dart';
import 'package:lextax_analysis/model/csv_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CodeController _codeController = CodeController();
  final _tokenRows = <DataRow>[];
  final CsvHandler _csvHandler = CsvHandler();
  final JsonHandler _jsonHandler = JsonHandler();
  bool _saveCsv = false;
  bool _saveJson = false;

  void _populateTokens(List<Token> tokens) {
    setState(() {
      _clearTokens();
      for (var token in tokens) {
        _tokenRows.add(DataRow(cells: [
          DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(token.value),
            ),
          ),
          DataCell(Text(token.type)),
        ]));
      }
    });
  }

  void _clearTokens() {
    setState(() {
      _tokenRows.clear();
    });
  }

  @override
  void initState() {
    _codeController.text = 'gui main() {\n\tprint(\'hello, xbox!\\n\');\n}';
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double getScreenWidth() => MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: max(getScreenWidth() * 0.45, 400),
            decoration: BoxDecoration(color: Theme.of(context).hoverColor),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Edit your code here'),
                  _spawnVerticalSpacer(16.0),
                  Expanded(
                    child: CodeTheme(
                      data: CodeThemeData(styles: googlecodeTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          background: Colors.transparent,
                          controller: _codeController,
                          gutterStyle: GutterStyle(
                            textStyle: GoogleFonts.jetBrainsMono(
                              fontSize: 16.0,
                              height: 1.5,
                            ),
                          ),
                          textStyle: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _spawnVerticalSpacer(16.0),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xbox'],
                            allowMultiple: false,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final input = utf8.decode(file.bytes as List<int>);
                            final fileExtension =
                                file.name.substring(file.name.length - 4);
                            if (fileExtension == 'xbox') {
                              setState(() {
                                _codeController.text = input;
                              });
                            } else {
                              Globals.snackBarNotif('Invalid file extension.');
                            }
                          }
                        },
                        icon: const Icon(Icons.upload_outlined),
                        tooltip: 'Upload a File',
                      ),
                      IconButton(
                        onPressed: () => _codeController.clear(),
                        icon: const Icon(Icons.backspace),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          Lexer lexer = Lexer(_codeController.fullText);
                          lexer.tokenize();
                          if (lexer.tokens.isNotEmpty) {
                            _populateTokens(lexer.tokens);
                            if (_saveCsv) {
                              List<List<String>> tokenList =
                                  _csvHandler.tokensToList(lexer.tokens);
                              String csv = _csvHandler.listToCsv(tokenList);
                              await _csvHandler.downloadCsv(csv);
                            }
                          } else {
                            Globals.snackBarNotif('No file detected.');
                          }
                        },
                        label: const Text('Tokenize'),
                        icon: const Icon(Icons.cookie_outlined),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0)),
                        ),
                      ),
                      _spawnHorizontalSpacer(16.0),
                      FilledButton.icon(
                        onPressed: () async {
                          Lexer lexer = Lexer(_codeController.fullText);
                          lexer.tokenize();
                          if (lexer.tokens.isNotEmpty) {
                            _populateTokens(lexer.tokens);
                            if (lexer.tokens.last.type == 'INVALID_TOKEN') {
                              Token invalid = lexer.tokens.last;
                              Globals.snackBarNotif(
                                  'INVALID_TOKEN detected at line ${invalid.line}:${invalid.col}. Fix program before parsing.');
                              return;
                            }
                            Parser parser = Parser(lexer.tokens);
                            ProgramNode? program = parser.parse();
                            if (_saveJson && program != null) {
                              await _jsonHandler.downloadJson(program);
                            }
                          } else {
                            Globals.snackBarNotif('No file detected.');
                          }
                        },
                        label: const Text('Analyze'),
                        icon: const Icon(Icons.code_outlined),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    title: Center(
                      child: Text(
                        'Lexer and Parser',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _tokenRows.isNotEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    dataRowMaxHeight: double.infinity,
                                    columns: const [
                                      DataColumn(
                                        label: Text('Lexeme'),
                                        headingRowAlignment:
                                            MainAxisAlignment.center,
                                      ),
                                      DataColumn(
                                        label: Text('Token'),
                                        headingRowAlignment:
                                            MainAxisAlignment.center,
                                      ),
                                    ],
                                    rows: _tokenRows,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notification_important_outlined),
                                Text('No input yet'),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Image(
                image: const AssetImage('assets/xbox_logo.png'),
                width: getScreenWidth() * 0.10,
              ),
              _spawnVerticalSpacer(4.0),
              const Text('Source Code'),
              _spawnVerticalSpacer(4.0),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      js.context.callMethod('open',
                          ['https://github.com/marcoxmediran/lextax_analysis']);
                    },
                    icon: const Icon(Icons.terminal),
                  ),
                  _spawnHorizontalSpacer(4.0),
                  IconButton(
                    onPressed: () {
                      js.context.callMethod('open', [
                        'https://github.com/marcoxmediran/lextax_analysis_web'
                      ]);
                    },
                    icon: const Icon(Icons.html),
                  ),
                ],
              ),
              const Spacer(),
              const Text('Output Settings'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Row(
                      children: [
                        Switch(
                          value: _saveCsv,
                          onChanged: (bool value) {
                            setState(
                              () {
                                _saveCsv = value;
                              },
                            );
                          },
                        ),
                        _spawnHorizontalSpacer(4.0),
                        const Text('Tokens (.csv)'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Row(
                      children: [
                        Switch(
                          value: _saveJson,
                          onChanged: (bool value) {
                            setState(
                              () {
                                _saveJson = value;
                              },
                            );
                          },
                        ),
                        _spawnHorizontalSpacer(4.0),
                        const Text('AST (.json)'),
                      ],
                    ),
                  ),
                ],
              ),
              _spawnVerticalSpacer(12.0),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _spawnVerticalSpacer(double height) {
  return SizedBox(height: height);
}

Widget _spawnHorizontalSpacer(double width) {
  return SizedBox(width: width);
}
