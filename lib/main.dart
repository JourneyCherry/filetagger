import 'package:file_picker/file_picker.dart';
import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/path_manager.dart';
import 'package:filetagger/Widgets/list_widget.dart';
import 'package:filetagger/Widgets/tag_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ko'),
        Locale('en'),
      ],
      locale: Locale('ko'),
      title: '',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyMainWidget(),
    );
  }
}

class MyMainWidget extends StatefulWidget {
  const MyMainWidget({
    super.key,
  });

  @override
  State<MyMainWidget> createState() => _MyMainWidgetState();
}

enum ViewType { list, icon }

class _MyMainWidgetState extends State<MyMainWidget> {
  String? appTitle;
  ViewType viewType = ViewType.list;
  GlobalData globalData = GlobalData();
  bool isSingleSelect = true;
  Set<int> selectedIndices = {};

  /// 트래킹할 root path를 가져오는 메소드. 첫 디렉토리 로드에 사용
  void _loadItems(String rootPath) async {
    PathManager().setRootPath(rootPath);
    globalData.clear();
    selectedIndices.clear();
    DirectoryReader().close();
    await DBManager().closeDatabase();

    if (await DBManager().initializeDatabase(rootPath) == false) {
      debugPrint('Failed to read Database');
      return; //TODO : 에러 표시하기.
    }
    globalData.pathData = await DBManager().getPaths() ?? {};
    globalData.tagData = await DBManager().getTags() ?? {};
    globalData.valueData = await DBManager().getValues() ?? {};

    setState(() {
      for (var kvp in globalData.valueData.entries) {
        final vid = kvp.value.vid;
        final pid = kvp.value.pid;
        if (globalData.pathData.containsKey(pid)) {
          globalData.pathData[pid]!.values.add(vid);
        } else {
          //TODO : valueData 제거하기.
        }
      }
    });

    final fileList = await DirectoryReader().readDirectory(rootPath);

    for (var entity in fileList) {
      final path = PathManager().getPath(entity.path);
      if (path == DBManager.dbMgrFileName) {
        //관리용 파일은 추가하지 않음
        continue;
      }
      setState(() {
        globalData.trackingPath.add(path);
      });
      final pid = globalData.getDataFromPath(path);
      if (pid == null) await DBManager().addFile(path);
    }

    setState(() {});
  }

  void _selectItem(int index) {
    setState(() {
      if (isSingleSelect) {
        selectedIndices.clear();
        selectedIndices.add(index);
      } else {
        if (selectedIndices.contains(index)) {
          selectedIndices.remove(index);
        } else {
          selectedIndices.add(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle ?? AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        leading: Tooltip(
          message: AppLocalizations.of(context)!.openDir,
          child: IconButton(
            onPressed: () async {
              final path = await FilePicker.platform.getDirectoryPath();
              if (path != null) {
                _loadItems(path);
                setState(() {
                  appTitle = path;
                });
              }
            },
            icon: Icon(Icons.file_copy),
          ),
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                '메뉴', //TODO : Localization
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.tag),
              title: Text(AppLocalizations.of(context)!.tagList),
              onTap: () async {
                Navigator.pop(context);
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return TagListDialog(initTagMap: globalData.tagData);
                  },
                );
                //TODO : TagListDialog에서 수정된 TagList를 가져와서 globalData.tagData와 비교하여 tid가 음수면 새 태그로, 변경된 값이 없으면 유지, 해당 tid의 태그가 없으면 삭제하여 globalData를 갱신
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                //TODO : 세팅 다이얼로그 띄우기
              },
            ),
          ],
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
            Area(
              builder: (context, area) {
                switch (viewType) {
                  case ViewType.list:
                    return ListWidget(
                      globalData: globalData,
                      selectedIndices: selectedIndices,
                      onTap: _selectItem,
                    );
                  case ViewType.icon:
                    return ListWidget(
                      globalData: globalData,
                      selectedIndices: selectedIndices,
                      onTap: _selectItem,
                    ); //TODO : GridWidget으로 바꾸기
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
