import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:filetagger/Widgets/tag_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ValueEditWidget extends StatefulWidget {
  final ValueData value;
  final void Function(ValueData)? onChanged;
  const ValueEditWidget({
    super.key,
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
    _textEditingController =
        TextEditingController(text: widget.value.value?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final tagList = context.select<TagDataProvider, List<TagData>>(
        (provider) => provider.getTagAll());
    if (widget.value.tid <= 0) {
      widget.value.tid = tagList.first.tid;
    }
    final tag = context.select<TagDataProvider, TagData?>(
        (provider) => provider.getTag(widget.value.tid));
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
                items: tagList
                    .map(
                      (tag) => DropdownMenuItem(
                        value: tag.tid,
                        child: Text(tag.name),
                      ),
                    )
                    .toList(),
                value: widget.value.tid,
                onChanged: (value) {
                  widget.value.tid = value ?? tagList.first.tid;
                  setState(() => widget.onChanged?.call(widget.value));
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: EditableTextWidget(
                controller: _textEditingController,
                onSaved: (str) {
                  widget.value.value =
                      Types.parseString(tag?.type ?? ValueType.label, str);
                  setState(() => widget.onChanged?.call(widget.value));
                },
                isValid: (value) => Types.isParsable(
                    tag?.type ?? ValueType.label, _textEditingController.text),
                defaultString: Types.parseString(tag?.type ?? ValueType.label,
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
