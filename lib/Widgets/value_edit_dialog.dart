import 'package:filetagger/Widgets/value_column_name_widget.dart';
import 'package:flutter/material.dart';

class ValueEditDialog extends StatelessWidget {
  const ValueEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('ValueEditDialog'),
        elevation: 16,
        content: SizedBox(
          width: 300,
          height: 80,
          child: Column(
            children: [
              ValueColumnNameWidget(),
            ],
          ),
        ),
        actions: [

        ]
    );
  }
}
