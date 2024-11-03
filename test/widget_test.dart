// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:filetagger/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test ListView Widget', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
        find.text('test'), findsNothing); //요소 찾기. 아직 없으므로 findsNothing이 나와야 한다.
    //TODO : ListWidget에 아이템들을 넣어 제대로 데이터를 표시하는지 확인
  });
}
