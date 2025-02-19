import 'package:flutter/material.dart';

class TagColumnNameWidget extends StatelessWidget {
  const TagColumnNameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: 50,
        child: Row(
          children: [
            Expanded(
              //드래그 핸들러
              flex: 1,
              child: Container(),
            ),
            Expanded(
              //태그 이름
              flex: 3,
              child: Text(
                'name',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              //태그 타입
              flex: 3,
              child: Text(
                'type',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              //태그 배경 색
              flex: 0,
              child: Text(
                'color',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              //태그 기본값
              flex: 4,
              child: Text(
                'default value',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              //중복 태그 허용
              flex: 1,
              child: Text(
                'duplicable',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              //필수 태그
              flex: 1,
              child: Text(
                'necessary',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
