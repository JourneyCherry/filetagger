import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:filetagger/Widgets/tag_widget.dart';
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
                itemBuilder: (context, index) {
                  if (index >= pathData.values.length) {
                    return TagIconWidget(
                      texts: [RichString('+', bold: true)],
                      onPressed: () {
                        //TODO : 태그 추가 다이얼로그 띄우기
                      },
                    );
                  } else {
                    final vid = pathData.values[index];
                    final valueData = globalData.getValue(vid)!;
                    final tagData = globalData.getTag(valueData.tid)!;
                    return TagWidget(
                      tag: tagData,
                      value: valueData,
                      onClick: (newTag) {
                        //TODO : 태그 수정 다이얼로그 띄우기
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
