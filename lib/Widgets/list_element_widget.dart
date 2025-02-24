import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:filetagger/Widgets/tag_widget.dart';
import 'package:filetagger/Widgets/value_edit_dialog.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatelessWidget {
  static final Color notExistColor = Colors.red.withValues(alpha: 0.3);
  static final Color selectedColor = Colors.blue.withValues(alpha: 0.3);
  final int pid;
  final GlobalData globalData;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isNotExist;
  const ListElementWidget({
    super.key,
    required this.pid,
    required this.globalData,
    required this.onTap,
    required this.isSelected,
    required this.isNotExist,
  });

  @override
  Widget build(BuildContext context) {
    Color nec = isNotExist ? notExistColor : Colors.transparent;
    Color sc = isSelected ? selectedColor : Colors.transparent;
    Color color = Color.alphaBlend(nec, sc);

    final pathData = globalData.pathData[pid]!;
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
                          if (globalData.tagData.isEmpty) {
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
                                globalData: globalData,
                                onPressed: (value) {
                                  //TODO : 다음 과정 수행
                                  //       1. 새 vid 생성
                                  //       2. globalData.values[newVid] = value
                                  //       3. 현재 목록 다시 빌드.
                                },
                              ),
                            );
                          }
                        },
                      ),
                    );
                  } else {
                    final vid = pathData.values[index];
                    final valueData = globalData.getValue(vid)!;
                    final tagData = globalData.getTag(valueData.tid)!;
                    return TagWidget(
                      tag: tagData,
                      value: valueData,
                      onClick: (curValue) {
                        //태그 수정 다이얼로그 띄우기
                        showDialog(
                          context: itemBuilderContext,
                          builder: (dialogBuildContext) => ValueEditDialog(
                            buttonText: 'add',
                            globalData: globalData,
                            valueData: curValue,
                            onPressed: (newValue) {
                              //TODO : 다음 과정 수행
                              //       1. globalData.values[newValue.vid] = newValue
                              //       2. 현재 목록 다시 빌드.
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
