import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/directory_manager.dart';
import 'package:filetagger/DataStructures/path_tag_value_provider.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:filetagger/Widgets/tag_widget.dart';
import 'package:filetagger/Widgets/value_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListElementWidget extends StatelessWidget {
  static final Color notExistColor = Colors.red.withValues(alpha: 0.3);
  static final Color selectedColor = Colors.blue.withValues(alpha: 0.3);
  final int pid;

  const ListElementWidget({
    super.key,
    required this.pid,
  });

  @override
  Widget build(BuildContext context) {
    final pathData = context.select<PathTagValueProvider?, PathData?>(
        (provider) => provider?.getPathData(pid));
    if (pathData == null) {
      return const SizedBox.shrink(); // (가능성은 낮지만) pid로 pathdata를 못찾으면 UI 숨김
    }

    final isExist = DirectoryManager().getFileEntity(pathData.path) == null;
    final isSelected = context.select<PathTagValueProvider?, bool?>(
            (provider) => provider?.isSelectedPID(pid)) ??
        false;

    Color nec = isExist ? Colors.transparent : notExistColor;
    Color sc = isSelected ? selectedColor : Colors.transparent;
    Color color = Color.alphaBlend(nec, sc);

    final vidList = pathData.values;

    return InkWell(
      onTap: () {
        if (isSelected) {
          context.read<PathTagValueProvider>().unselectPID(pid);
        } else {
          //TODO : Shift 키가 눌린 상태, ctrl 키가 눌린 상태에 대해서 처리 필요
          context.read<PathTagValueProvider>().selectPID(pid);
        }
      },
      child: Container(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(pathData.path),
            ),
            SizedBox(
              height: TagIconWidget.height,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: vidList.length + 1,
                itemBuilder: (itemBuilderContext, index) {
                  if (index >= vidList.length) {
                    return SizedBox(
                      width: 20,
                      child: TagIconWidget(
                        texts: [RichString('+', bold: true)],
                        onPressed: () {
                          if (context
                                  .read<PathTagValueProvider>()
                                  .getTagCount() ==
                              0) {
                            // 태그가 없으면 값을 등록할 수 없으니 경고창 띄우기
                            showDialog(
                              context: itemBuilderContext,
                              builder: (dialogBuilderContext) =>
                                  AlertDialog.adaptive(
                                content: Text(
                                    'Any tag needed'), //TODO : Localization
                              ),
                            );
                          } else {
                            //태그 추가 다이얼로그 띄우기
                            showDialog(
                              context: itemBuilderContext,
                              builder: (dialogBuildContext) => ValueEditDialog(
                                buttonText: 'add', //TODO : Localization
                              ),
                            );
                          }
                        },
                      ),
                    );
                  } else {
                    final vid = vidList.elementAt(index);
                    final valueData = itemBuilderContext.select<
                        PathTagValueProvider,
                        ValueData?>((provider) => provider.getValueData(vid));
                    if (valueData == null) return null;
                    final tagData = itemBuilderContext
                        .select<PathTagValueProvider, TagData?>(
                            (provider) => provider.getTagData(valueData.tid));
                    if (tagData == null) return null;
                    return TagWidget(
                      tag: tagData,
                      value: valueData,
                      onClick: (curValue) {
                        //태그 수정 다이얼로그 띄우기
                        showDialog(
                          context: itemBuilderContext,
                          builder: (dialogBuildContext) => ValueEditDialog(
                            buttonText: 'modify',
                            valueData: curValue,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
