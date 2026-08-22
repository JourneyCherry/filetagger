import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/common/type_ahead.dart';
import 'package:filetagger/presentation/widgets/type_ahead_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 감싸인 목록이 다시 세워졌는지 세는 자리표시자(상태 유지 확인용).
int _probeInits = 0;

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _probeInits++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  testWidgets('검색어가 생겨도 감싸인 목록은 다시 세워지지 않는다', (tester) async {
    _probeInits = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TypeAheadOverlay(child: _Probe()),
        ),
      ),
    );
    expect(_probeInits, 1);
    expect(find.text('ab'), findsNothing);

    container
        .read(typeAheadProvider.notifier)
        .type('a', names: const ['abc'], current: -1);
    container
        .read(typeAheadProvider.notifier)
        .type('b', names: const ['abc'], current: 0);
    await tester.pump();

    // 목록(자식)은 그대로 살아 있어야 한다 — 첫 글자에 스크롤·드릴인 위치가 사라지면
    // 빠른 탐색이 되레 자리를 잃게 만든다.
    expect(_probeInits, 1);
    expect(find.text('ab'), findsOneWidget);

    // 유효 시간이 지나면 검색어와 표시가 함께 사라진다.
    await tester.pump(kTypeAheadTimeout);
    await tester.pump();
    expect(find.text('ab'), findsNothing);
    expect(_probeInits, 1);
  });
}
