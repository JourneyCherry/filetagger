import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:flutter/material.dart';

/// 태그 표시용 작은 위젯
class TagWidget extends StatelessWidget {
  final TagData tag;
  final ValueData value;
  final void Function(ValueData)? onClick;
  const TagWidget({
    super.key,
    required this.tag,
    required this.value,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    String? valueStr;
    valueStr = value.value; //TODO : tag.type에 따라서 value.value를 문자열로 변경하기.
    return TagIconWidget(
      onPressed: () => onClick?.call(value),
      backgroundColor: tag.bgColor,
      texts: [
        RichString(tag.name, bold: true),
        if (valueStr != null) RichString(': $valueStr'),
      ],
    );
  }
}
