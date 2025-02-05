import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class TagEditWidget extends StatelessWidget {
  final TagData tag;
  final void Function(TagData)? onChanged;

  const TagEditWidget({
    super.key,
    required this.tag,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 50,
      child: Row(
        //TODO : 각 child Widget들의 크기 조절
        children: [
          //TODO : Editable Widget으로 표시
          //TODO : 수정 시, callback 호출
          Text(tag.tid.toString()),
          Text(tag.name),
          Text(tag.type.toString()),
          Text(tag.txtColor.toString()),
          Text(tag.bgColor.toString()),
          Text(tag.order.toString()),
          Text(tag.defaultValue ?? ''),
          Text(tag.duplicable.toString()),
          Text(tag.necessary.toString()),
        ],
      ),
    );
  }
}
