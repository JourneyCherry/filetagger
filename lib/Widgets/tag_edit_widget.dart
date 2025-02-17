import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:filetagger/Widgets/tag_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TagEditWidget extends StatefulWidget {
  final TagData tag;
  final void Function(TagData)? onChanged;
  final int index;

  const TagEditWidget({
    super.key,
    required this.tag,
    this.onChanged,
    required this.index,
  });

  @override
  State<TagEditWidget> createState() => _TagEditWidgetState();
}

class _TagEditWidgetState extends State<TagEditWidget> {
  late String name_;
  late String defaultValue_;

  @override
  void initState() {
    super.initState();
    setValues();
  }

  @override
  void didUpdateWidget(TagEditWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      setState(() => setValues());
    }
  }

  void setValues() {
    name_ = widget.tag.name;
    if (widget.tag.defaultValue == null) {
      defaultValue_ = '';
    } else {
      defaultValue_ = widget.tag.defaultValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutBuilderContext, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: 50,
          child: Row(
            children: [
              Expanded(
                //드래그 핸들러
                flex: 1,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: Icon(Icons.drag_indicator),
                ),
              ),
              Expanded(
                //태그 이름
                flex: 3,
                child: EditableTextWidget(
                  initialText: name_,
                  onSaved: (String str) {
                    setState(() {
                      if (str.isNotEmpty) widget.tag.name = str;
                      name_ = str;
                      widget.onChanged?.call(widget.tag);
                    });
                  },
                  isValid: (value) => value.isNotEmpty,
                  defaultString: widget.tag.name,
                ),
              ),
              Expanded(
                //태그 타입
                flex: 3,
                child: DropdownButton(
                    isExpanded: true,
                    alignment: Alignment.center,
                    value: widget.tag.type,
                    items: ValueType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              TypeLocalizations.getTypeName(
                                  layoutBuilderContext, type),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      widget.tag.type = value!;
                      widget.tag.defaultValue =
                          Types.parseString(widget.tag.type, defaultValue_);
                      setState(() => widget.onChanged?.call(widget.tag));
                    }),
              ),
              Expanded(
                //태그 배경 색
                flex: 0,
                child: TagIconWidget(
                  texts: [RichString('Color')],
                  backgroundColor: widget.tag.bgColor,
                  onPressed: () {
                    showDialog(
                      context: layoutBuilderContext,
                      builder: (dialogContext) {
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
                              pickerColor: widget.tag.bgColor,
                              onColorChanged: (value) {
                                widget.tag.bgColor = value;
                                setState(
                                    () => widget.onChanged?.call(widget.tag));
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
                  initialText: defaultValue_,
                  onSaved: (str) {
                    setState(() {
                      widget.tag.defaultValue =
                          Types.parseString(widget.tag.type, str);
                      widget.onChanged?.call(widget.tag);
                    });
                  },
                  isValid: (value) => Types.isParsable(widget.tag.type, value),
                  defaultString:
                      Types.parseString(widget.tag.type, defaultValue_)
                          .toString(),
                ),
              ),
              Expanded(
                //중복 태그 허용
                flex: 1,
                child: Checkbox(
                  value: widget.tag.duplicable,
                  onChanged: (value) {
                    widget.tag.duplicable = value!;
                    setState(() => widget.onChanged?.call(widget.tag));
                  },
                ),
              ),
              Expanded(
                //필수 태그
                flex: 1,
                child: Checkbox(
                  value: widget.tag.necessary,
                  onChanged: (value) {
                    widget.tag.necessary = value!;
                    setState(() => widget.onChanged?.call(widget.tag));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
