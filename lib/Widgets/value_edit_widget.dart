import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:flutter/material.dart';

class ValueEditWidget extends StatefulWidget {
  final ValueData value;
  final Map<int, TagData> tags;
  final void Function(ValueData)? onChanged;
  const ValueEditWidget({
    super.key,
    required this.tags,
    required this.value,
    this.onChanged,
  });

  @override
  State<ValueEditWidget> createState() => _ValueEditWidgetState();
}

class _ValueEditWidgetState extends State<ValueEditWidget> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    if (widget.value.tid <= 0) {
      widget.value.tid = widget.tags.keys.first;
    }
    _textEditingController =
        TextEditingController(text: widget.value.value?.toString());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutBuilderContext, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: 50,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButton(
                isExpanded: true,
                alignment: Alignment.centerLeft,
                items: widget.tags.values
                    .map(
                      (tag) => DropdownMenuItem(
                        value: tag.tid,
                        child: Text(tag.name),
                      ),
                    )
                    .toList(),
                value: widget.value.tid,
                onChanged: (value) {
                  widget.value.tid = value ?? widget.tags.keys.first;
                  setState(() => widget.onChanged?.call(widget.value));
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: EditableTextWidget(
                controller: _textEditingController,
                onSaved: (str) {
                  widget.value.value = Types.parseString(
                      widget.tags[widget.value.tid]?.type ?? ValueType.label,
                      str);
                  setState(() => widget.onChanged?.call(widget.value));
                },
                isValid: (value) => Types.isParsable(
                    widget.tags[widget.value.tid]?.type ?? ValueType.label,
                    _textEditingController.text),
                defaultString: Types.parseString(
                        widget.tags[widget.value.tid]?.type ?? ValueType.label,
                        _textEditingController.text)
                    .toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
