import 'package:flutter/material.dart';

class ValueColumnNameWidget extends StatelessWidget {
  const ValueColumnNameWidget({super.key});

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
              child: Text(
                'Tag',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'value',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
