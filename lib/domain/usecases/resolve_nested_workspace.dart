import '../entities/folder_manage_mode.dart';
import '../entities/nested_merge_resolution.dart';
import '../entities/nested_tagger_mode.dart';
import '../repositories/file_node_repository.dart';
import '../repositories/nested_workspace_merger.dart';
import '../repositories/nested_workspace_repository.dart';

/// 중첩 워크스페이스에 대한 사용자 결정을 적용하는 오케스트레이션.
///
/// 각 방식의 실제 동작(내부 인덱싱 여부)은 폴더 노드의 관리 방식 override로
/// 표현하고, 프롬프트 반복을 막는 확정 기록은 별도 저장소에 남긴다. 흡수는 하위
/// DB 이관을 [NestedWorkspaceMerger]에 위임한다.
class ResolveNestedWorkspace {
  const ResolveNestedWorkspace(this._fileNodes, this._nested, this._merger);

  final FileNodeRepository _fileNodes;
  final NestedWorkspaceRepository _nested;
  final NestedWorkspaceMerger _merger;

  Future<void> call({
    required String parentRoot,
    required NestedMergeResolution resolution,
  }) async {
    final path = resolution.childRelPath;
    switch (resolution.action) {
      case NestedMergeAction.independent:
        // 내부 미탐색 단일 노드 = 불투명.
        await _fileNodes.setManageModeByPath(
          path: path,
          mode: FolderManageMode.opaque,
        );
        await _nested.record(path, NestedTaggerMode.independent);

      case NestedMergeAction.ignore:
        // 내부를 상위 규칙으로 전부 인덱싱 = 재귀 관리.
        await _fileNodes.setManageModeByPath(
          path: path,
          mode: FolderManageMode.managedRecursive,
        );
        await _nested.record(path, NestedTaggerMode.ignore);

      case NestedMergeAction.absorb:
        await _merger.absorb(
          parentRoot: parentRoot,
          childRelPath: path,
          removeSource: resolution.removeSource,
        );
        // 흡수한 내부 노드가 이후 재스캔에서 정리되지 않도록 폴더를 재귀 관리로
        // 둔다. 하위 태거를 남긴 경우(제거 안 함)에는 '무시'로 확정 기록해 프롬프트
        // 반복을 막는다(제거한 경우엔 남는 중첩이 없어 기록이 불필요).
        await _fileNodes.setManageModeByPath(
          path: path,
          mode: FolderManageMode.managedRecursive,
        );
        if (!resolution.removeSource) {
          await _nested.record(path, NestedTaggerMode.ignore);
        }
    }
  }
}
