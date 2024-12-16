import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_widget.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatelessWidget {
  static final Color notExistColor = Colors.red.withOpacity(0.3);
  static final Color selectedColor = Colors.blue.withOpacity(0.3);
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
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pathData.tags.length + 1,
                itemBuilder: (context, index) {
                  return TagWidget(
                    globalData: globalData,
                    bgColor: Colors.blue.withOpacity(0.7),
                    ftColor: Colors.white,
                    valueId: pathData.tags.contains(index)
                        ? pathData.tags[index]
                        : null,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
