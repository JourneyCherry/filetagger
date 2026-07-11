import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/nested_merge_resolution.dart';
import 'package:filetagger/domain/entities/nested_tagger_mode.dart';
import 'package:filetagger/domain/repositories/file_node_repository.dart';
import 'package:filetagger/domain/repositories/nested_workspace_merger.dart';
import 'package:filetagger/domain/repositories/nested_workspace_repository.dart';
import 'package:filetagger/domain/usecases/resolve_nested_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

/// 중첩 병합 결정이 (1) 폴더 관리 방식, (2) 확정 기록, (3) 흡수 이관/원본 제거로
/// 올바르게 분기되는지에 대한 가드레일.
void main() {
  late _FakeFileNodes files;
  late _FakeNested nested;
  late _FakeMerger merger;
  late ResolveNestedWorkspace resolve;

  setUp(() {
    files = _FakeFileNodes();
    nested = _FakeNested();
    merger = _FakeMerger();
    resolve = ResolveNestedWorkspace(files, nested, merger);
  });

  test('독립: 폴더를 불투명으로 두고 independent로 기록한다', () async {
    await resolve(
      parentRoot: '/root',
      resolution: const NestedMergeResolution(
        childRelPath: 'a/b',
        action: NestedMergeAction.independent,
      ),
    );

    expect(files.mode['a/b'], FolderManageMode.opaque);
    expect(nested.recorded['a/b'], NestedTaggerMode.independent);
    expect(merger.calls, isEmpty);
  });

  test('무시: 폴더를 재귀 관리로 두고 ignore로 기록한다', () async {
    await resolve(
      parentRoot: '/root',
      resolution: const NestedMergeResolution(
        childRelPath: 'a/b',
        action: NestedMergeAction.ignore,
      ),
    );

    expect(files.mode['a/b'], FolderManageMode.managedRecursive);
    expect(nested.recorded['a/b'], NestedTaggerMode.ignore);
    expect(merger.calls, isEmpty);
  });

  test('흡수(제거): 흡수 후 재귀 관리로 두되 기록하지 않는다', () async {
    await resolve(
      parentRoot: '/root',
      resolution: const NestedMergeResolution(
        childRelPath: 'a/b',
        action: NestedMergeAction.absorb,
        removeSource: true,
      ),
    );

    expect(merger.calls, [('/root', 'a/b', true)]);
    expect(files.mode['a/b'], FolderManageMode.managedRecursive);
    // 원본을 지웠으면 남는 중첩이 없어 확정 기록이 불필요하다.
    expect(nested.recorded, isEmpty);
  });

  test('흡수(잔존): 흡수 후 재귀 관리로 두고 ignore로 기록한다', () async {
    await resolve(
      parentRoot: '/root',
      resolution: const NestedMergeResolution(
        childRelPath: 'a/b',
        action: NestedMergeAction.absorb,
        removeSource: false,
      ),
    );

    expect(merger.calls, [('/root', 'a/b', false)]);
    expect(files.mode['a/b'], FolderManageMode.managedRecursive);
    expect(nested.recorded['a/b'], NestedTaggerMode.ignore);
  });
}

class _FakeFileNodes implements FileNodeRepository {
  final Map<String, FolderManageMode> mode = {};

  @override
  Future<void> setManageModeByPath({
    required String path,
    required FolderManageMode mode,
  }) async {
    this.mode[path] = mode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeNested implements NestedWorkspaceRepository {
  final Map<String, NestedTaggerMode> recorded = {};

  @override
  Future<Set<String>> decidedPaths() async => recorded.keys.toSet();

  @override
  Future<void> record(String childRelPath, NestedTaggerMode mode) async {
    recorded[childRelPath] = mode;
  }

  @override
  Future<void> remove(String childRelPath) async {
    recorded.remove(childRelPath);
  }
}

class _FakeMerger implements NestedWorkspaceMerger {
  /// (parentRoot, childRelPath, removeSource) 호출 기록.
  final List<(String, String, bool)> calls = [];

  @override
  Future<void> absorb({
    required String parentRoot,
    required String childRelPath,
    required bool removeSource,
  }) async {
    calls.add((parentRoot, childRelPath, removeSource));
  }
}
