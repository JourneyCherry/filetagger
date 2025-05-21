import 'package:file_picker/file_picker.dart';
import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/DataStructures/path_manager.dart';
import 'package:filetagger/Widgets/list_widget.dart';
import 'package:filetagger/Widgets/tag_data_provider.dart';
import 'package:filetagger/Widgets/tag_list_controller.dart';
import 'package:filetagger/Widgets/tag_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TagDataProvider>(
            create: (_) => TagDataProvider()),
      ],
      child: MaterialApp(
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
      ),
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
  bool isSingleSelect = true;
  Set<int> selectedIndices = {};

  /// 트래킹할 root path를 가져오는 메소드. 첫 디렉토리 로드에 사용
  void _loadItems(String rootPath) async {
    //초기화
    PathManager().setRootPath(rootPath);
    selectedIndices.clear();
    DirectoryReader().close();
    await DBManager().closeDatabase();

    //DB로부터 데이터 읽어오기
    if (await DBManager().initializeDatabase(rootPath) == false) {
      debugPrint('Failed to read Database');
      return; //TODO : 에러 표시하기.
    }
    globalData.pathData = await DBManager().getPaths() ?? {};
    globalData.tagData = await DBManager().getTags() ?? {};
    globalData.valueData = await DBManager().getValues() ?? {};

    // ValueData를 각 해당하는 PathData에 매칭 시키기
    setState(() {
      for (var kvp in globalData.valueData.entries) {
        final vid = kvp.value.vid;
        final pid = kvp.value.pid;
        if (globalData.pathData.containsKey(pid)) {
          globalData.pathData[pid]!.values.add(vid);
        }
        //vDB자체적으로 ValueData의 pid는 Foreign Key이기에 삭제되는 경우는 없다.
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
      if (pid == null) await DBManager().createPath(path);
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
              onTap: () {
                final srcTagList = context.read<TagDataProvider>().getTagAll();
                TagListController controller = TagListController(srcTagList);
                TagListDialog dialog = TagListDialog(controller: controller);
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return dialog;
                  },
                );
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
                      selectedIndices: selectedIndices,
                      onTap: _selectItem,
                      onValueChanged: () => setState(() {}),
                    );
                  case ViewType.icon:
                    return ListWidget(
                      selectedIndices: selectedIndices,
                      onTap: _selectItem,
                      onValueChanged: () => setState(() {}),
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
