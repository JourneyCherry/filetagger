import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatelessWidget {
  final PathData pathData;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isExist;
  const ListElementWidget({
    super.key,
    required this.pathData,
    required this.onTap,
    required this.isSelected,
    required this.isExist,
  });

  @override
  Widget build(BuildContext context) {
    Color notExistColor =
        isExist ? Colors.red.withOpacity(0.3) : Colors.transparent;
    Color selectColor =
        isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent;
    Color color = Color.alphaBlend(selectColor, notExistColor);
    return ListTile(
      title: Text(pathData.path),
      onTap: onTap,
      tileColor: (isExist || isSelected) ? color : null,
    );
  }
}
