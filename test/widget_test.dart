// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:filetagger/Widgets/list_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test ListView Widget', (WidgetTester tester) async {
    await tester.pumpWidget(const ListWidget());
    //TODO : ListWidget에 아이템들을 넣어 제대로 데이터를 표시하는지 확인
  });
}
