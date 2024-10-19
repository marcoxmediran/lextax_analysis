import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lextax_analysis/model/lexer.dart';
import 'package:lextax_analysis/model/token.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final QuillController _controller = QuillController.basic();
  final _tokenRows = <DataRow>[];

  void _populateTokens(List<Token> tokens) {
    setState(() {
      _clearTokens();
      for (var token in tokens) {
        _tokenRows.add(DataRow(cells: [
          DataCell(Text(token.value)),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _getScreenWidth() => MediaQuery.sizeOf(context).width;
    double _getScreenHeight() => MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: max(_getScreenWidth() * 0.3, 350),
            decoration: BoxDecoration(color: Theme.of(context).hoverColor),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Edit your code here'),
                  _spawnVerticalSpacer(16.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          width: 0.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: QuillEditor.basic(
                          controller: _controller,
                          configurations: const QuillEditorConfigurations(),
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
                              await FilePicker.platform.pickFiles();
                          if (result != null) {
                            PlatformFile file = result.files.first;
                            String input = utf8.decode(file.bytes as List<int>);
                            setState(() {
                              _controller.document.delete(0, _controller.document.length);
                              _controller.document.insert(0, input);
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_outlined),
                        tooltip: 'Upload a File',
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          Lexer lexer =
                              Lexer(_controller.document.toPlainText());
                          lexer.tokenize();
                          _populateTokens(lexer.tokens);
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
                        onPressed: () {},
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
                    title: Center(
                      child: Text('PPL 3-1N Group 1 Project'),
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
                                    columns: const [
                                      DataColumn(label: Text('Lexeme')),
                                      DataColumn(label: Text('Token')),
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
