import 'package:filetagger/presentation/common/focus_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 뷰포트 높이. 행 높이와 함께 기대 스크롤 위치를 손으로 셀 수 있게 고정한다.
const double _viewport = 300;
const double _rowHeight = 100;
const int _rowCount = 40;

/// 커서 행과 요청을 밖에서 조종할 수 있는 목록. 캐시 범위는 기본값 그대로 두어 화면에서
/// 먼 행은 실제로 버려지고 다시 만들어지게 한다(휠 스크롤과 같은 조건).
Future<void> _pumpList(
  WidgetTester tester, {
  required RowRevealRequest request,
  required ValueNotifier<int> cursor,
  required ScrollController controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: _viewport,
          child: ValueListenableBuilder<int>(
            valueListenable: cursor,
            builder: (context, active, _) => ListView.builder(
              controller: controller,
              itemCount: _rowCount,
              itemBuilder: (context, index) => EnsureVisibleOnFocus(
                active: index == active,
                request: request,
                child: SizedBox(height: _rowHeight, child: Text('행 $index')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// 노출이 애니메이션으로 도는 플랫폼(테스트의 기본값)이라 기대값은 pumpAndSettle 뒤에
// 본다 — 데스크톱은 전환 시간이 0이라 같은 자리에 곧바로 선다.
void main() {
  group('RowRevealRequest', () {
    test('아무도 올리지 않았으면 받을 것이 없다', () {
      expect(RowRevealRequest().isPending, isFalse);
    });

    test('올리면 남고, 받으면 사라진다', () {
      final request = RowRevealRequest()..request();
      expect(request.isPending, isTrue);
      request.serve();
      expect(request.isPending, isFalse);
    });

    test('처리 전에 겹쳐 올려도 한 번 받으면 끝난다', () {
      final request = RowRevealRequest()
        ..request()
        ..request()
        ..serve();
      expect(request.isPending, isFalse);
    });

    test('받은 뒤 다시 올리면 새 요청이 된다', () {
      final request = RowRevealRequest()
        ..request()
        ..serve()
        ..request();
      expect(request.isPending, isTrue);
    });
  });

  group('EnsureVisibleOnFocus', () {
    testWidgets('요청이 없으면 커서 행이 다시 만들어져도 스크롤을 뺏지 않는다', (tester) async {
      // 휠 버그의 자리다 — 화면 밖으로 밀려나 버려졌던 커서 행은 그쪽으로 스크롤하면
      // 다시 만들어지는데, 그때마다 자기를 드러내면 굴리던 스크롤이 튄다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(20);
      addTearDown(cursor.dispose);
      await _pumpList(
        tester,
        request: RowRevealRequest(),
        cursor: cursor,
        controller: controller,
      );

      controller.jumpTo(1750); // 커서 행(2000~2100)이 캐시 범위에 들어오는 자리
      await tester.pumpAndSettle();

      expect(controller.offset, 1750);
    });

    testWidgets('요청이 있으면 아래로 벗어난 커서 행을 끝만 걸치게 끌어온다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      final request = RowRevealRequest();
      await _pumpList(
        tester,
        request: request,
        cursor: cursor,
        controller: controller,
      );

      request.request();
      cursor.value = 5; // 500~600. 뷰포트는 0~300이라 아래로 벗어나 있다.
      await tester.pumpAndSettle();

      // 가운데(450)가 아니라 모자란 만큼만: 행 끝(600)이 뷰포트 끝에 닿는 자리.
      expect(controller.offset, 600 - _viewport);
    });

    testWidgets('위로 벗어난 커서 행은 앞머리를 뷰포트 앞머리에 맞춘다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(10);
      addTearDown(cursor.dispose);
      final request = RowRevealRequest();
      await _pumpList(
        tester,
        request: request,
        cursor: cursor,
        controller: controller,
      );
      controller.jumpTo(1000);
      await tester.pumpAndSettle();

      request.request();
      cursor.value = 8; // 800~900. 뷰포트는 1000~1300이라 위로 벗어나 있다.
      await tester.pumpAndSettle();

      expect(controller.offset, 800);
    });

    testWidgets('이미 온전히 보이는 행이면 요청이 있어도 움직이지 않는다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      final request = RowRevealRequest();
      await _pumpList(
        tester,
        request: request,
        cursor: cursor,
        controller: controller,
      );

      request.request();
      cursor.value = 1; // 100~200. 뷰포트 0~300 안에 온전히 들어 있다.
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
    });

    testWidgets('요청은 한 번만 쓰인다 — 받은 뒤에는 같은 행이 다시 그려져도 가만있다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      final request = RowRevealRequest();
      await _pumpList(
        tester,
        request: request,
        cursor: cursor,
        controller: controller,
      );

      request.request();
      cursor.value = 5;
      await tester.pumpAndSettle();
      expect(request.isPending, isFalse);

      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
    });
  });

  group('jumpNearRow', () {
    testWidgets('평균 행 높이로 어림해 그 행이 가운데 오도록 옮긴다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      await _pumpList(
        tester,
        request: RowRevealRequest(),
        cursor: cursor,
        controller: controller,
      );

      expect(jumpNearRow(controller, 30, _rowCount), isTrue);
      await tester.pump();

      // 행 높이가 고르면 어림이 정확하다: 3000에서 반 화면 앞.
      expect(controller.offset, 3000 - _viewport / 2);
    });

    testWidgets('이미 그 자리면 옮기지 않는다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      await _pumpList(
        tester,
        request: RowRevealRequest(),
        cursor: cursor,
        controller: controller,
      );
      jumpNearRow(controller, 30, _rowCount);
      await tester.pump();

      expect(jumpNearRow(controller, 30, _rowCount), isFalse);
    });

    testWidgets('행 범위 밖이거나 붙은 목록이 없으면 아무 일도 하지 않는다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      expect(jumpNearRow(controller, 3, _rowCount), isFalse); // 붙은 목록 없음
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      await _pumpList(
        tester,
        request: RowRevealRequest(),
        cursor: cursor,
        controller: controller,
      );

      expect(jumpNearRow(controller, -1, _rowCount), isFalse);
      expect(jumpNearRow(controller, _rowCount, _rowCount), isFalse);
      expect(jumpNearRow(controller, 0, 0), isFalse);
    });
  });

  group('CursorRevealMixin', () {
    testWidgets('행 높이가 들쭉날쭉해 어림이 크게 빗나가도 끝내 그 행을 드러낸다', (tester) async {
      // 앞 30줄은 얕고 뒤 10줄은 깊어 평균이 어느 쪽과도 맞지 않는다. 어림 착지만으로는
      // 그 행이 만들어지지 않아, 앞뒤를 더듬어 찾아내야 한다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: _viewport,
              child: _UnevenList(controller: controller),
            ),
          ),
        ),
      );

      tester.state<_UnevenListState>(find.byType(_UnevenList)).moveCursor(35);
      await tester.pumpAndSettle();

      // 35번 행은 2200~2400(앞 30줄 40씩 + 5줄 200씩). 아래로 벗어나 있었으므로 끝을
      // 뷰포트 끝에 맞춘 자리에 선다.
      expect(controller.offset, 2400 - _viewport);
      expect(find.text('행 35'), findsOneWidget);
    });
  });
}

/// 앞뒤 행 높이가 크게 다른 목록(어림이 빗나가는 상황을 만든다).
class _UnevenList extends StatefulWidget {
  const _UnevenList({required this.controller});

  final ScrollController controller;

  @override
  State<_UnevenList> createState() => _UnevenListState();
}

class _UnevenListState extends State<_UnevenList>
    with CursorRevealMixin<_UnevenList> {
  int _cursor = 0;

  @override
  ScrollController get revealScrollController => widget.controller;

  @override
  int get cursorRowIndex => _cursor;

  @override
  int get revealRowCount => _rowCount;

  void moveCursor(int index) {
    setState(() => _cursor = index);
    requestCursorReveal();
  }

  static double _heightOf(int index) => index < 30 ? 40 : 200;

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: widget.controller,
    itemCount: _rowCount,
    itemBuilder: (context, index) => EnsureVisibleOnFocus(
      active: index == _cursor,
      request: cursorReveal,
      child: SizedBox(height: _heightOf(index), child: Text('행 $index')),
    ),
  );
}
