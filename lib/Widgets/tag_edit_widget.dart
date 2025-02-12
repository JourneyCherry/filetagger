import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: 50,
        child: Row(
          children: [
            Expanded(
              //태그 번호 //TODO : 유저에겐 보여줄 필요 없음
              flex: 1,
              child: Text(tag.tid.toString()),
            ),
            Expanded(
              //태그 이름
              flex: 3,
              child: EditableTextWidget(
                initialText: tag.name,
                onSaved: (String str) {
                  tag.name = str;
                  onChanged?.call(tag);
                },
              ),
            ),
            Expanded(
              //태그 타입
              flex: 2,
              child: Text(tag.type.toString()),
            ),
            Expanded(
              //태그 글자 색  //TODO : 선택을 없애고 배경색의 보색 또는 무채색인데 잘 보이는 색상으로 조정 필요
              flex: 1,
              child: Text(tag.txtColor.toString()),
            ),
            Expanded(
              //태그 배경 색
              flex: 1,
              child: Text(tag.bgColor.toString()),
            ),
            Expanded(
              //태그 순서 //TODO : 유저에겐 보여줄 필요 없음
              flex: 1,
              child: Text(tag.order.toString()),
            ),
            Expanded(
              flex: 3,
              child: EditableTextWidget(
                initialText: tag.defaultValue ?? '',
                onSaved: (str) {
                  //TODO : tag.type에 따라 값 타입 설정
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Checkbox(
                value: tag.duplicable,
                onChanged: (value) {
                  tag.duplicable = value!;
                  onChanged?.call(tag);
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Checkbox(
                value: tag.necessary,
                onChanged: (value) {
                  tag.necessary = value!;
                  onChanged?.call(tag);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
