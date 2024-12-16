import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class TagWidget extends StatelessWidget {
  static const double maxWidth = 150;
  static const double height = 30;
  final Color bgColor;
  final Color ftColor;
  final int? valueId;
  final GlobalData globalData;
  const TagWidget({
    super.key,
    this.valueId,
    required this.globalData,
    required this.bgColor,
    required this.ftColor,
  });

  void showAddValueDialog() {
    //TODO : 태그값을 추가하는 다이얼로그 띄우기
  }
  void showModifyValueDialog() {
    //TODO : 태그값을 변경하는 다이얼로그 띄우기
  }

  @override
  Widget build(BuildContext context) {
    final valueData = globalData.valueData[valueId];
    final tagData = globalData.tagData[valueData?.tid];
    final tagText = tagData?.name ?? '+';
    final valueText = valueData?.value?.toString() ?? '';
    return InkWell(
      onTap: (valueId != null) ? showModifyValueDialog : showAddValueDialog,
      child: Container(
        height: height,
        constraints: const BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tagText,
              style: TextStyle(
                color: ftColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                valueText,
                style: TextStyle(
                  color: ftColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
