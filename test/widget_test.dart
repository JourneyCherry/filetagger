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
    expect(find.byType(MyMainWidget), findsOne); //메인 위젯이 등장해야함.

    tester.pumpAndSettle(); //모든 애니메이션과 타이머가 완료될 때까지 대기

    //TODO : 디렉토리 읽은 뒤, listviewitem이 등장하는지 확인
  });
}
