import 'package:filetagger/presentation/tag_visuals.dart';
import 'package:filetagger/presentation/widgets/color_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 다이얼로그가 돌려준 값을 담아 두는 상자. 취소와 '아직 안 닫힘'을 구분하려고
/// 닫혔는지를 따로 들고 있는다.
class _Picked {
  bool closed = false;
  int? color;
}

Future<_Picked> _open(WidgetTester tester, {int? initialColor}) async {
  final picked = _Picked();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked.color = await showColorPickerDialog(
                context,
                initialColor: initialColor,
              );
              picked.closed = true;
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return picked;
}

/// R·G·B 세 칸은 놓인 순서대로 찾는다.
const int _red = 0;
const int _green = 1;
const int _blue = 2;

Finder _field(int index) => find.byType(TextField).at(index);

String _text(WidgetTester tester, int index) =>
    tester.widget<TextField>(_field(index)).controller!.text;

/// 세 칸이 함께 가리키는 색.
int _shownColor(WidgetTester tester) =>
    opaqueTagColorBits |
    (int.parse(_text(tester, _red)) << 16) |
    (int.parse(_text(tester, _green)) << 8) |
    int.parse(_text(tester, _blue));

/// 채도·명도 판과 색상 띠. 둘 다 제 크기를 재려고 LayoutBuilder를 쓰고, 그리는
/// 순서대로 판이 먼저다.
Finder get _area => find.byType(LayoutBuilder).at(0);
Finder get _hueBar => find.byType(LayoutBuilder).at(1);

void main() {
  const initial = 0xFF64B5F6;

  testWidgets('연 색이 R·G·B 칸에 나뉘어 들어가 있다', (tester) async {
    await _open(tester, initialColor: initial);

    expect(_text(tester, _red), '100');
    expect(_text(tester, _green), '181');
    expect(_text(tester, _blue), '246');
  });

  testWidgets('고를 색을 주지 않으면 팔레트의 첫 색에서 시작한다', (tester) async {
    await _open(tester);

    expect(_shownColor(tester), tagColorPalette.first);
  });

  testWidgets('칸을 고쳐 치고 확인하면 그 색을 돌려준다', (tester) async {
    final picked = await _open(tester, initialColor: initial);

    await tester.enterText(_field(_red), '16');
    await tester.enterText(_field(_green), '32');
    await tester.enterText(_field(_blue), '48');
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(picked.closed, isTrue);
    expect(picked.color, 0xFF102030);
  });

  testWidgets('채널이 담을 수 없는 숫자는 칸에 들어가지 않는다', (tester) async {
    await _open(tester, initialColor: initial);

    await tester.enterText(_field(_red), '255');
    await tester.pump();
    await tester.enterText(_field(_red), '256');
    await tester.pump();

    // 잘라 고쳐 쓰지 않고 거부하므로 직전 값이 그대로 남는다.
    expect(_text(tester, _red), '255');
  });

  testWidgets('숫자가 아닌 글자는 칸에 남지 않는다', (tester) async {
    await _open(tester, initialColor: initial);

    await tester.enterText(_field(_red), 'a7b');
    await tester.pump();

    expect(_text(tester, _red), '7');
  });

  testWidgets('칸을 비우면 바닥값으로 읽는다', (tester) async {
    final picked = await _open(tester, initialColor: initial);

    await tester.enterText(_field(_red), '');
    await tester.enterText(_field(_green), '');
    await tester.enterText(_field(_blue), '');
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(picked.color, 0xFF000000);
  });

  testWidgets('취소하면 색을 돌려주지 않는다', (tester) async {
    final picked = await _open(tester, initialColor: initial);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(picked.closed, isTrue);
    expect(picked.color, isNull);
  });

  testWidgets('ESC로 닫아도 색을 돌려주지 않는다', (tester) async {
    final picked = await _open(tester, initialColor: initial);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(picked.closed, isTrue);
    expect(picked.color, isNull);
  });

  testWidgets('판의 왼쪽 아래를 누르면 채도와 명도가 바닥으로 간다', (tester) async {
    await _open(tester, initialColor: initial);

    final rect = tester.getRect(_area);
    await tester.tapAt(rect.bottomLeft + const Offset(0.5, -0.5));
    await tester.pump();

    final hsv = HSVColor.fromColor(Color(_shownColor(tester)));
    expect(hsv.saturation, lessThan(0.05));
    expect(hsv.value, lessThan(0.05));
  });

  testWidgets('판을 눌러 고른 색이 확인으로 그대로 나간다', (tester) async {
    final picked = await _open(tester, initialColor: initial);

    final rect = tester.getRect(_area);
    await tester.tapAt(rect.topRight + const Offset(-0.5, 0.5));
    await tester.pump();
    final shown = _shownColor(tester);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(shown, isNot(initial));
    expect(picked.color, shown);
  });

  testWidgets('띠의 왼쪽 끝을 누르면 색상이 색상환의 처음으로 간다', (tester) async {
    await _open(tester, initialColor: initial);

    final rect = tester.getRect(_hueBar);
    await tester.tapAt(rect.centerLeft + const Offset(0.5, 0));
    await tester.pump();

    final hsv = HSVColor.fromColor(Color(_shownColor(tester)));
    expect(hsv.hue, lessThan(5));
  });

  testWidgets('명도를 바닥까지 내렸다 올려도 색상을 잃지 않는다', (tester) async {
    // 검정은 색상값이 어디를 가리키든 같은 정수라, 정수로만 들고 있었다면 되돌아온
    // 색이 색상환의 처음으로 튄다.
    await _open(tester, initialColor: initial);
    final hue = HSVColor.fromColor(const Color(initial)).hue;

    final rect = tester.getRect(_area);
    await tester.tapAt(rect.bottomLeft + const Offset(0.5, -0.5));
    await tester.pump();
    await tester.tapAt(rect.topRight + const Offset(-0.5, 0.5));
    await tester.pump();

    final hsv = HSVColor.fromColor(Color(_shownColor(tester)));
    expect(hsv.hue, closeTo(hue, 1));
  });

  testWidgets('칸으로 무채색을 만들어도 색상환의 처음으로 튀지 않는다', (tester) async {
    await _open(tester, initialColor: initial);

    // 칸을 하나씩 고치는 동안 색상이 옮겨 가는 것은 당연하다(파랑만 남으면 색상도
    // 파랑 자리다). 검정이 되기 **직전**의 그 자리를 재 둔다.
    await tester.enterText(_field(_red), '0');
    await tester.enterText(_field(_green), '0');
    await tester.pump();
    final before = HSVColor.fromColor(Color(_shownColor(tester))).hue;

    await tester.enterText(_field(_blue), '0');
    await tester.pump();

    // 판을 오른쪽 위로 되돌리면 그 색상이 그대로 서 있어야 한다.
    final rect = tester.getRect(_area);
    await tester.tapAt(rect.topRight + const Offset(-0.5, 0.5));
    await tester.pump();

    final hsv = HSVColor.fromColor(Color(_shownColor(tester)));
    expect(hsv.hue, closeTo(before, 1));
  });
}
