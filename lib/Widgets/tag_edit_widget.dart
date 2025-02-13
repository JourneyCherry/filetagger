import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
              //TODO : 드래그 핸들러 기능 추가
              flex: 1,
              child: Icon(Icons.drag_indicator),
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
              flex: 3,
              child: Text(tag.type.toString()),
            ),
            Expanded(
              //태그 배경 색  //TODO : 글자 색을 auto로 둔 경우, 그 예시를 보여주기 위해 TagWidget을 그대로 가져와서 보여주자.
              flex: 1,
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (buildContext) {
                      return AlertDialog(
                        titlePadding: const EdgeInsets.all(0),
                        contentPadding: const EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(500),
                            bottom: Radius.circular(100),
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: HueRingPicker(
                            portraitOnly: true,
                            pickerColor: tag.bgColor,
                            onColorChanged: (value) {
                              tag.bgColor = value;
                              onChanged?.call(tag);
                            },
                            enableAlpha: false,
                            displayThumbColor: true,
                          ),
                        ),
                      );
                    },
                  );
                },
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                icon: Icon(
                  Icons.circle,
                  color: tag.bgColor,
                ),
              ),
            ),
            Expanded(
              flex: 4,
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
