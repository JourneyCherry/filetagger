import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/usecases/apply_external_commands.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/widgets/import_result_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

ExternalTagCommand _command({String path = 'photos/a.jpg', String? value}) =>
    ExternalTagCommand(targetPath: path, tagName: '작가', value: value);

Future<void> _pumpDialog(
  WidgetTester tester, {
  required List<ExternalCommandResult> results,
  int unreadable = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showImportResultDialog(
              context,
              results: results,
              unreadable: unreadable,
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('적용된 항목은 세기만 하고 늘어놓지 않는다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandApplied(_command(path: 'a.jpg')),
        CommandApplied(_command(path: 'b.jpg')),
      ],
    );

    // 잘된 일을 줄줄이 보여도 읽을 이유가 없다.
    expect(find.text('a.jpg'), findsNothing);
    expect(find.text(koL10n.importSummary(2, 0, 0)), findsOneWidget);
  });

  testWidgets('서지 못한 항목만 목록에 오른다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandApplied(_command(path: 'a.jpg')),
        CommandHeld(_command(path: 'b.jpg')),
        CommandRejected(
          _command(path: 'c.jpg'),
          CommandFailureReason.tagMissing,
        ),
      ],
    );

    expect(find.text('a.jpg'), findsNothing);
    expect(find.text('b.jpg'), findsOneWidget);
    expect(find.text('c.jpg'), findsOneWidget);
  });

  testWidgets('보류와 거부는 사유 자리에서 갈린다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandHeld(_command()),
        CommandRejected(_command(), CommandFailureReason.valueTypeMismatch),
      ],
    );

    // 둘 다 "안 붙었다"는 같지만, 보류는 스캔 뒤 다시 가져오면 서고 거부는 고쳐야 선다.
    expect(find.text(koL10n.importHeldLabel), findsOneWidget);
    expect(find.text(koL10n.importReasonValueTypeMismatch), findsOneWidget);
    expect(find.text(koL10n.importHeldHint), findsOneWidget);
  });

  testWidgets('보류가 없으면 스캔 안내도 없다', (tester) async {
    await _pumpDialog(
      tester,
      results: [CommandRejected(_command(), CommandFailureReason.systemTag)],
    );

    expect(find.text(koL10n.importHeldHint), findsNothing);
  });

  testWidgets('읽어 내지 못한 항목은 수로만 알린다', (tester) async {
    await _pumpDialog(tester, results: const [], unreadable: 2);

    // 판정이 아니라 형식 오류라 목록에 담을 항목 자체가 없다.
    expect(find.text(koL10n.importUnreadable(2)), findsOneWidget);
    expect(find.text(koL10n.importUnreadableHint), findsOneWidget);
    expect(find.text(koL10n.importItemsToFix), findsNothing);
  });

  testWidgets('해석기가 덧붙인 세부 갈래를 그대로 보인다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandRejected(
          _command(value: '다섯'),
          CommandFailureReason.invalidValue,
          CommandFailureDetail.notNumber,
        ),
      ],
    );

    // 사유만으로는 같은 사유 안의 어느 갈래인지 알 수 없어, 고칠 자리를 짚지 못한다.
    // 갈래는 순수 Dart 계층이 낸 이름이라 **번역하지 않고 그대로** 보인다.
    expect(find.text(CommandFailureDetail.notNumber.name), findsOneWidget);
    expect(find.text(koL10n.importReasonInvalidValue), findsOneWidget);
  });

  testWidgets('갈래가 짚어 주는 원문이 있으면 함께 보인다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandRejected(
          _command(),
          CommandFailureReason.malformed,
          CommandFailureDetail.keywordNameInvalid,
          'separator',
        ),
      ],
    );

    expect(
      find.text('${CommandFailureDetail.keywordNameInvalid.name}: separator'),
      findsOneWidget,
    );
  });

  testWidgets('태그값이 있으면 함께 보인다', (tester) async {
    await _pumpDialog(
      tester,
      results: [
        CommandRejected(
          _command(value: '김아무개'),
          CommandFailureReason.tagMissing,
        ),
      ],
    );

    // 어디가 문제인지는 항목이 스스로 말해야 한다(자세한 설명은 콘솔이 낸다).
    expect(find.textContaining('김아무개'), findsOneWidget);
  });
}
