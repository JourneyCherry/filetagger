import 'package:filetagger/l10n/app_localizations.dart';
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
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  group('measuredRowOffset', () {
    testWidgets('깔려 있는 행은 정확한 자리를 낸다', (tester) async {
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

      // 화면에 있는 행은 어림이 아니라 렌더 트리에서 잰 값이다.
      expect(measuredRowOffset(controller, 2, _rowCount), 2 * _rowHeight);
    });

    testWidgets('아직 없는 행은 깔린 구간의 국소 평균으로 외삽한다', (tester) async {
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

      // 높이가 고르면 외삽도 정확하다.
      expect(measuredRowOffset(controller, 30, _rowCount), 30 * _rowHeight);
    });

    testWidgets('행 범위 밖이거나 붙은 목록이 없으면 잴 것이 없다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      expect(measuredRowOffset(controller, 3, _rowCount), isNull); // 붙은 목록 없음
      final cursor = ValueNotifier(0);
      addTearDown(cursor.dispose);
      await _pumpList(
        tester,
        request: RowRevealRequest(),
        cursor: cursor,
        controller: controller,
      );

      expect(measuredRowOffset(controller, -1, _rowCount), isNull);
      expect(measuredRowOffset(controller, _rowCount, _rowCount), isNull);
      expect(measuredRowOffset(controller, 0, 0), isNull);
    });
  });

  group('jumpNearRow', () {
    testWidgets('잰 자리를 기준으로 그 행이 가운데 오도록 옮긴다', (tester) async {
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

      // 30번 행 앞머리(3000)에서 반 화면 앞.
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

    testWidgets('잴 것이 없으면 아무 일도 하지 않는다', (tester) async {
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
    testWidgets('행 높이가 들쭉날쭉해도 되풀이가 그 행으로 수렴한다', (tester) async {
      // 앞 30줄은 얕고 뒤 10줄은 깊어 전체 평균은 어느 쪽과도 맞지 않는다. 한 번 옮길
      // 때마다 깔린 구간이 목표 쪽으로 가므로 다음 번 어림이 더 정확해져야 한다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('긴 행 쪽에서 짧은 행 쪽으로 건너뛰어도 드러낸다', (tester) async {
      // 어림이 **넘겨짚는** 방향이다 — 깊은 행들 사이에 서서 얕은 행을 겨누면 목표를
      // 지나쳐 내리게 되고, 그 길에 스쳐 만들어진 커서 행이 요청만 삼킬 수 있다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: _viewport,
              child: _UnevenList(controller: controller),
            ),
          ),
        ),
      );
      final state = tester.state<_UnevenListState>(find.byType(_UnevenList));

      state.moveCursor(35);
      await tester.pumpAndSettle();
      state.moveCursor(20);
      await tester.pumpAndSettle();

      // 20번 행(800~840)이 가운데 오도록 내려앉고, 거기서 이미 온전히 보이므로 더
      // 움직이지 않는다.
      expect(find.text('행 20'), findsOneWidget);
      expect(controller.offset, 800 - _viewport / 2);
    });
  });

  group('stepTowardRow', () {
    testWidgets('행이 아직 없으면 뷰가 정한 걸음으로 옮긴다', (tester) async {
      // 제 행 자리를 아는 목록은 어림을 되풀이할 것 없이 한 걸음에 닿는다. 그 걸음을
      // 뷰가 갈아 끼울 수 있어야 한다 — 목록 보기가 인덱스 점프로 갈아 끼운 자리다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final calls = <int>[];
      await _pumpStepped(
        tester,
        controller: controller,
        calls: calls,
        step: (index) => index * _rowHeight,
      );

      tester.state<_SteppedListState>(find.byType(_SteppedList)).moveCursor(30);
      await tester.pumpAndSettle();

      // 한 걸음이면 닿으므로 그 뒤로는 다시 부르지 않는다(행이 요청을 받아 갔다).
      expect(calls, [30]);
      expect(controller.offset, 30 * _rowHeight);
      expect(find.text('행 30'), findsOneWidget);
    });

    testWidgets('더 갈 데 없다고 하면 되풀이를 멈춘다', (tester) async {
      // 걸음이 false를 내면 요청을 접어야 한다. 접지 않으면 프레임을 다 쓸 때까지
      // 같은 자리를 헛되이 다시 겨눈다.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final calls = <int>[];
      await _pumpStepped(
        tester,
        controller: controller,
        calls: calls,
        step: (_) => null,
      );

      tester.state<_SteppedListState>(find.byType(_SteppedList)).moveCursor(30);
      await tester.pumpAndSettle();

      expect(calls, [30]);
      expect(controller.offset, 0);
    });
  });
}

/// [_SteppedList]를 뷰포트에 띄운다.
Future<void> _pumpStepped(
  WidgetTester tester, {
  required ScrollController controller,
  required List<int> calls,
  required double? Function(int index) step,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: _viewport,
        child: _SteppedList(controller: controller, calls: calls, step: step),
      ),
    ),
  ),
);

/// 커서 행으로 가는 **한 걸음을 밖에서 정하는** 목록. 행 높이가 고른 것은 기대 위치를
/// 손으로 셀 수 있게 하려는 것이다(여기서 보려는 것은 어림의 정확도가 아니라 걸음을
/// 갈아 끼울 수 있는지다).
class _SteppedList extends StatefulWidget {
  const _SteppedList({
    required this.controller,
    required this.calls,
    required this.step,
  });

  final ScrollController controller;

  /// 걸음이 불린 행 번호를 순서대로 담는다.
  final List<int> calls;

  /// 한 걸음에 갈 자리. null이면 더 갈 데가 없다고 알린다.
  final double? Function(int index) step;

  @override
  State<_SteppedList> createState() => _SteppedListState();
}

class _SteppedListState extends State<_SteppedList>
    with CursorRevealMixin<_SteppedList> {
  int _cursor = 0;

  @override
  ScrollController get revealScrollController => widget.controller;

  @override
  int get cursorRowIndex => _cursor;

  @override
  int get revealRowCount => _rowCount;

  @override
  bool stepTowardRow(int index) {
    widget.calls.add(index);
    final to = widget.step(index);
    if (to == null) return false;
    widget.controller.jumpTo(to);
    return true;
  }

  void moveCursor(int index) {
    setState(() => _cursor = index);
    requestCursorReveal();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: widget.controller,
    itemCount: _rowCount,
    itemBuilder: (context, index) => EnsureVisibleOnFocus(
      active: index == _cursor,
      request: cursorReveal,
      child: SizedBox(height: _rowHeight, child: Text('행 $index')),
    ),
  );
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
