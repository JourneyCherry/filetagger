import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/db_manager.dart';
import 'package:filetagger/DataStructures/error_code.dart';
import 'package:filetagger/Widgets/tag_data_provider.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:filetagger/Widgets/tag_widget.dart';
import 'package:filetagger/Widgets/value_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListElementWidget extends StatelessWidget {
  static final Color notExistColor = Colors.red.withValues(alpha: 0.3);
  static final Color selectedColor = Colors.blue.withValues(alpha: 0.3);
  final int pid;
  final VoidCallback? onTap;
  final VoidCallback? onSuccess;
  final bool isSelected;
  final bool isNotExist;
  const ListElementWidget({
    super.key,
    required this.pid,
    required this.onTap,
    required this.isSelected,
    required this.isNotExist,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    Color nec = isNotExist ? notExistColor : Colors.transparent;
    Color sc = isSelected ? selectedColor : Colors.transparent;
    Color color = Color.alphaBlend(nec, sc);

    final pathData = context.select<TagDataProvider, PathData?>(
        (provider) => provider.getPath(pid));
    if (pathData == null) {
      return Container();
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        color: (isNotExist || isSelected) ? color : null,
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
                itemCount: pathData.values.length + 1,
                itemBuilder: (itemBuilderContext, index) {
                  if (index >= pathData.values.length) {
                    return SizedBox(
                      width: 20,
                      child: TagIconWidget(
                        texts: [RichString('+', bold: true)],
                        onPressed: () {
                          if (context.read<TagDataProvider>().getTagCount() ==
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
                                onPressed: (value) async {
                                  value.pid = pid;
                                  ErrorCode ec = dialogBuildContext
                                      .read<TagDataProvider>()
                                      .setValue(value);
                                  if (ec != ErrorCode.success) {
                                    //TODO : 추가 실패 메시지 띄우기
                                    return false;
                                  }
                                  ec = await DBManager().setValue(value);
                                  if (ec != ErrorCode.success) {
                                    //TODO : 추가 실패 메시지 띄우기
                                    return false;
                                  }
                                  onSuccess?.call();
                                  return true;
                                },
                              ),
                            );
                          }
                        },
                      ),
                    );
                  } else {
                    final vid = pathData.values.elementAt(index);
                    final valueData =
                        itemBuilderContext.select<TagDataProvider, ValueData?>(
                            (provider) => provider.getValue(vid));
                    if (valueData == null) return null;
                    final tagData =
                        itemBuilderContext.select<TagDataProvider, TagData?>(
                            (provider) => provider.getTag(valueData.tid));
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
                            onPressed: (value) async {
                              //다이얼로그가 종료되면 더이상 다이얼로그가 표시되지 않으므로 갱신하지 않음
                              ErrorCode ec = dialogBuildContext
                                  .read<TagDataProvider>()
                                  .setValue(value);
                              if (ec != ErrorCode.success) {
                                //TODO : 수정 실패 메시지 띄우기
                                return false;
                              }
                              ec = await DBManager().setValue(value);
                              if (ec != ErrorCode.success) {
                                //TODO : 수정 실패 메시지 띄우기
                                return false;
                              }
                              onSuccess?.call();
                              return true;
                            },
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
