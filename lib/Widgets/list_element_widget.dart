import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatelessWidget {
  static final Color notExistColor = Colors.red.withOpacity(0.3);
  static final Color selectedColor = Colors.blue.withOpacity(0.3);
  final PathData pathData;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isNotExist;
  const ListElementWidget({
    super.key,
    required this.pathData,
    required this.onTap,
    required this.isSelected,
    required this.isNotExist,
  });

  @override
  Widget build(BuildContext context) {
    Color nec = isNotExist ? notExistColor : Colors.transparent;
    Color sc = isSelected ? selectedColor : Colors.transparent;
    Color color = Color.alphaBlend(nec, sc);
    return ListTile(
      title: Text(pathData.path),
      onTap: onTap,
      tileColor: (isNotExist || isSelected) ? color : null,
    );
  }
}
