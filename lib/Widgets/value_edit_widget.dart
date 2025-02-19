import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/editable_text_widget.dart';
import 'package:flutter/material.dart';

class ValueEditWidget extends StatefulWidget {
  final GlobalData globalData;
  final int? initTid;
  final dynamic initValue;
  final void Function(int, String)? onChanged;
  const ValueEditWidget({
    super.key,
    required this.globalData,
    this.initTid,
    this.initValue,
    this.onChanged,
  });

  @override
  State<ValueEditWidget> createState() => _ValueEditWidgetState();
}

class _ValueEditWidgetState extends State<ValueEditWidget> {
  late int tid_;
  late String value_;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    tid_ = widget.initTid ?? -1;
    value_ = widget.initValue?.toString() ?? '';
    _textEditingController = TextEditingController(text: value_);
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
                items: widget.globalData.tagData.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  tid_ = value ?? -1;
                  setState(() => widget.onChanged?.call(tid_, value_));
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: EditableTextWidget(
                controller: _textEditingController,
                onSaved: (str) {
                  value_ = str;
                  setState(() => widget.onChanged?.call(tid_, value_));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
