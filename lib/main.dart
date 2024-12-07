import 'package:file_picker/file_picker.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/Widgets/list_widget.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileTagger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("FileTagger"),
          centerTitle: true,
          leading: Tooltip(
            message: "Open Directory",
            child: IconButton(
              onPressed: () async {
                final path = await FilePicker.platform.getDirectoryPath();
                DirectoryReader().readDirectory(path);
              },
              icon: Icon(Icons.file_copy),
            ),
          ),
        ),
        body: MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
              dividerPainter: DividerPainters.grooved1(
                  color: Colors.indigo[100]!,
                  highlightedColor: Colors.indigo[400]!)),
          child: MultiSplitView(
            initialAreas: [
              Area(builder: (context, area) => Draft.blue()),
              Area(builder: (context, area) => ListWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
