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
                'Tag', //TODO : Localization
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'value', //TODO : Localization
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
