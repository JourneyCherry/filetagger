import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/types.dart';
import 'package:filetagger/Widgets/value_column_name_widget.dart';
import 'package:filetagger/Widgets/value_edit_widget.dart';
import 'package:flutter/material.dart';

class ValueEditDialog extends StatefulWidget {
  final void Function(ValueData)? onPressed;
  final String buttonText;
  final GlobalData globalData;

  /// 다이얼로그에서 처리하는 ValueData가 의존하는 PathData. [valueData]가 입력되면 해당 값의 pid를 우선한다.
  final PathData? pathData;

  /// 다이얼로그에서 처리하는 ValueData. 이 값이 입력되면 [pathData]의 pid는 무시한다.
  final ValueData? valueData;
  const ValueEditDialog({
    super.key,
    this.onPressed,
    required this.buttonText,
    required this.globalData,
    this.valueData,
    this.pathData,
  });

  @override
  State<ValueEditDialog> createState() => _ValueEditDialogState();
}

class _ValueEditDialogState extends State<ValueEditDialog> {
  late ValueData valueData;

  @override
  void initState() {
    super.initState();
    if (widget.valueData != null) {
      valueData = widget.valueData!;
    } else {
      valueData = ValueData.partial(
        pid: widget.pathData?.pid ?? -1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text('ValueEditDialog'), //TODO : Localization
      elevation: 16,
      content: SizedBox(
        width: 300,
        height: 100,
        child: Column(
          children: [
            ValueColumnNameWidget(),
            ValueEditWidget(
              tags: widget.globalData.tagData,
              initTid: valueData.tid,
              initValue: valueData.value,
              onChanged: (newTid, newValue) {
                setState(() {
                  valueData.tid = newTid;
                  var tag = widget.globalData.getTag(valueData.tid);
                  if (tag == null) {
                    //태그가 없으면 value도 없어야 한다.
                    valueData.value = null;
                  } else {
                    valueData.value = Types.parseString(tag.type, newValue);
                  }
                });
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onPressed?.call(valueData),
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}
