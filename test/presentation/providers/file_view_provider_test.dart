import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/file_tree_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/presentation/providers/file_node_provider.dart';
import 'package:filetagger/presentation/providers/file_view_provider.dart';
import 'package:filetagger/presentation/providers/tag_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _indexed = [
  FileNode(id: 1, path: 'a.txt', kind: NodeKind.file),
  FileNode(id: 2, path: 'b.txt', kind: NodeKind.file),
];

Future<ProviderContainer> _containerWith(FileFilter filter) async {
  final container = ProviderContainer(
    overrides: [
      fileNodesProvider.overrideWith((ref) => Stream.value(_indexed)),
    ],
  );
  container.read(viewSettingsProvider.notifier).updateFilter(filter);
  await container.read(fileNodesProvider.future);
  return container;
}

void main() {
  // 스캔 표시를 띄울지 가르는 기준. 이 둘을 같은 것으로 보면, 인덱스가 이미 차
  // 있는데도 조건이 아무것도 못 내는 순간 목록이 스캔 표시에 가려진다.
  group('인덱스가 비었는지와 조건에 맞는 것이 없는지는 다른 상태다', () {
    test('아무것도 통과하지 못하는 필터에서도 인덱스 수는 그대로다', () async {
      // 아무 노드도 갖지 않은 태그를 요구하는 조건 — 통과하는 노드가 없다.
      final container = await _containerWith(
        const FileFilter(conditions: [FilterCondition(tagDefinitionId: 99)]),
      );
      addTearDown(container.dispose);

      expect(container.read(visibleNodeCountProvider), 0);
      expect(container.read(indexedNodeCountProvider), _indexed.length);
    });

    test('조건이 없으면 같은 인덱스가 그대로 다 보인다', () async {
      final container = await _containerWith(const FileFilter());
      addTearDown(container.dispose);

      expect(container.read(visibleNodeCountProvider), _indexed.length);
      expect(container.read(indexedNodeCountProvider), _indexed.length);
    });
  });

  test('인덱스가 실리기 전에는 센 값이 0이다', () {
    final container = ProviderContainer(
      overrides: [
        fileNodesProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(indexedNodeCountProvider), 0);
  });

  // 접고 펴는 것은 사용자가 쥔 상태다. 필터가 이것을 덮으면 조건을 거는 순간 접어 둔
  // 그룹이 통째로 쏟아지고, 그 상태에서는 헤더를 눌러도 닫히지 않는다.
  test('필터가 걸려도 접어 둔 그룹은 접힌 채로 남는다', () async {
    const def = TagDefinition(id: 7, name: '작가', valueType: TagValueType.text);
    const files = [
      FileNode(id: 20, path: 'f1.txt', kind: NodeKind.file),
      FileNode(id: 21, path: 'f2.txt', kind: NodeKind.file),
    ];
    final assignments = [
      for (final node in files)
        AssignedTag(
          assignment: TagAssignment(
            fileNodeId: node.id!,
            tagDefinitionId: def.id!,
            value: '값${node.id}',
          ),
          definition: def,
        ),
    ];

    final container = ProviderContainer(
      overrides: [
        fileNodesProvider.overrideWith((ref) => Stream.value(files)),
        tagDefinitionsProvider.overrideWith((ref) => Stream.value(const [def])),
        assignmentsProvider.overrideWith((ref) => Stream.value(assignments)),
      ],
    );
    addTearDown(container.dispose);
    container.read(viewSettingsProvider.notifier)
      ..updateGrouping(const FileGrouping(keys: [TagGroupKey(7)]))
      ..updateFilter(
        const FileFilter(conditions: [FilterCondition(tagDefinitionId: 7)]),
      );
    await container.read(fileNodesProvider.future);
    await container.read(assignmentsProvider.future);

    final flat = container.read(flatTreeProvider).valueOrNull!;

    // 버킷은 만들어졌지만(헤더 둘) 아무것도 펼쳐지지 않아 노드 행이 없다.
    expect(flat.rows, hasLength(2));
    expect(flat.rows.every((r) => r.item is GroupHeaderNode), isTrue);
    expect(flat.rows.every((r) => !r.expanded), isTrue);
    expect(flat.nodes, isEmpty);
  });
}
