import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/l10n/app_localizations.dart';
import 'package:filetagger/presentation/providers/system_tag_provider.dart';
import 'package:filetagger/presentation/widgets/preview_pane.dart';
import 'package:filetagger/presentation/widgets/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _node = FileNode(id: 1, path: 'memo.txt', kind: NodeKind.file);

AssignedTag _tag(int id, String name) => AssignedTag(
  assignment: TagAssignment(fileNodeId: 1, tagDefinitionId: id, value: '값$id'),
  definition: TagDefinition(id: id, name: name, valueType: TagValueType.text),
);

/// 사용자 태그 하나와 시스템 태그 하나 — 감춤 규칙이 서로 반대라 둘을 함께 둔다.
final _tags = [_tag(1, '색상'), _tag(SystemTag.extension.id, '확장자')];

void main() {
  testWidgets('프리뷰는 목록에서 감춘 태그도 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveAssignmentsByFileProvider.overrideWithValue({1: _tags}),
          // 목록 행이라면 칩이 하나도 남지 않을 설정. 프리뷰가 이 술어를 다시
          // 거치게 되면 칩이 사라져 이 테스트가 깨진다.
          tagChipVisibleProvider.overrideWithValue((_) => false),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: PreviewPane(
                node: _node,
                selectedCount: 1,
                onEditAssignment: (_) {},
                onRemoveAssignment: (_) {},
                onAddTag: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssignedTagChip), findsNWidgets(2));
  });
}
