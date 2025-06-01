import 'dart:async';
import 'dart:io';

import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/directory_manager.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:filetagger/DataStructures/path_tag_value_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ListWidget extends StatefulWidget {
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  final VoidCallback? onValueChanged;
  const ListWidget({
    super.key,
    this.selectedIndices = const {},
    this.onTap,
    this.onValueChanged,
  });

  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  final Set<String> _pathFromDir = {};
  late StreamSubscription<DirectoryChangeEvent> _subscription;

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  void initState() {
    _subscription = DirectoryManager().onChange.listen(onDirectoryEvent);
    _pathFromDir.addAll(DirectoryManager().getFilePathList());
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void onDirectoryEvent(DirectoryChangeEvent event) {
    setState(() {
      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          _pathFromDir.add(event.path);
          break;
        case FileSystemEvent.delete:
        case FileSystemEvent.move:
          _pathFromDir.remove(event.path);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<String> pathList = {};

    // DB에 저장된 목록 가져오기
    final pathFromDB = context.select<PathTagValueProvider, List<PathData>>(
        (provider) => provider.getPathAll());
    pathList.addAll(pathFromDB.map((pathData) => pathData.path));

    // 실제 파일 목록 가져오기
    pathList.addAll(_pathFromDir);

    if (pathList.isEmpty) return getEmptyWidget(context);
    return ListView.builder(
      itemCount: pathList.length,
      itemBuilder: (listViewBuilderContext, index) {
        String path = pathList.elementAt(index);
        PathData? pathData;
        final pid =
            listViewBuilderContext.read<PathTagValueProvider>().getPid(path);
        if (pid != null) {
          pathData = listViewBuilderContext
              .read<PathTagValueProvider>()
              .getPathData(pid);
        }
        return ListElementWidget(
          path: path,
          pathData: pathData,
          onTap: () => widget.onTap?.call(pathData?.pid ?? 0),
          onSuccess: widget.onValueChanged,
          isSelected: widget.selectedIndices.contains(index),
          isNotExist: DirectoryManager().getFileEntity(path) ==
              null, // FileSystemEntity를 불러오지 못하면 존재하지 않는 파일
        );
      },
    );
  }
}
