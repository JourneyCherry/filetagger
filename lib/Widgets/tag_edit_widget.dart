import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
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
              child: DropdownButton(
                  isExpanded: true,
                  alignment: Alignment.center,
                  value: tag.type,
                  items: ValueType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            TypeLocalizations.getTypeName(context, type),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    tag.type = value!;
                    tag.defaultValue = Types.parseString(tag.type,
                        tag.defaultValue); //TODO : tag.defaultValue는 dynamic인데 기본값 필드는 EditableTextWidget으로 String?값을 갖는다. 해결 필요
                    onChanged?.call(tag);
                  }),
            ),
            Expanded(
              //태그 배경 색
              flex: 0,
              child: TagIconWidget(
                texts: [RichString('Color')],
                backgroundColor: tag.bgColor,
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
              ),
            ),
            Expanded(
              //태그 기본값
              flex: 4,
              child: EditableTextWidget(
                initialText:
                    tag.defaultValue == null ? '' : tag.defaultValue.toString(),
                onSaved: (str) {
                  tag.defaultValue = Types.parseString(tag.type,
                      str); //TODO : Types.isParsable() == false면 아래에 빨갛게 타입이 맞지 않아 default값으로 바뀔수 있다고 경고창 띄우기
                  onChanged?.call(tag);
                },
              ),
            ),
            Expanded(
              //중복 태그 허용
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
              //필수 태그
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
