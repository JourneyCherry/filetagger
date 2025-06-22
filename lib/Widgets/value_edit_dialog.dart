import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/DataStructures/error_code.dart';
import 'package:filetagger/DataStructures/path_tag_value_provider.dart';
import 'package:filetagger/Widgets/value_column_name_widget.dart';
import 'package:filetagger/Widgets/value_edit_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ValueEditDialog extends StatefulWidget {
  final String buttonText;

  /// 다이얼로그에서 처리하는 ValueData가 의존하는 PathData. [valueData]가 입력되면 해당 값의 pid를 우선한다.
  final PathData? pathData;

  /// 다이얼로그에서 처리하는 ValueData. 이 값이 입력되면 [pathData]의 pid는 무시한다.
  final ValueData? valueData;
  const ValueEditDialog({
    super.key,
    required this.buttonText,
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
              value: valueData,
              onChanged: (newValue) {
                setState(() {
                  valueData = newValue;
                });
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ErrorCode ec;
            ec = context.read<PathTagValueProvider>().verifyValue(valueData);
            if (ec != ErrorCode.success) {
              //TODO : 에러코드에 따른 에러 메시지 띄우기
              return;
            }
            if (valueData.vid < 0) {
              valueData.vid = context.read<PathTagValueProvider>().getNewVID();
            }
            ec = context.read<PathTagValueProvider>().setValue(valueData);
            if (ec != ErrorCode.success) {
              //TODO : 에러코드에 따른 에러 메시지 띄우기
              return;
            }

            Navigator.pop(context);
          },
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}
