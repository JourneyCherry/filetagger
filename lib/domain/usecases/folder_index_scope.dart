import '../entities/file_node.dart';
import '../entities/folder_manage_mode.dart';

/// 폴더 관리 방식의 **상속·인덱싱 범위**를 계산하는 순수 로직.
///
/// 폴더의 저장값(`FileNode.manageMode`)은 명시적 override이고, null이면 부모의
/// effective 모드를 상속한다. 상속 규칙:
/// - 부모 effective가 [FolderManageMode.managedRecursive]면 자식(override 없음)도
///   재귀 관리를 물려받는다.
/// - 부모 effective가 [FolderManageMode.managed]면 자식(override 없음)은 불투명이
///   되어 더 내려가지 않는다.
/// - 불투명 폴더는 내부를 인덱싱하지 않으므로 그 자식 노드는 존재하지 않는다.
///
/// 스캐너(data)는 스캔 중 같은 규칙으로 재귀 여부를 정하고, presentation은 이
/// 함수들로 표시(effective 모드)와 범위 축소 경고(사라질 노드)를 계산한다.

/// override 없는 자식이 부모의 effective 모드에서 물려받는 모드.
FolderManageMode inheritedChildMode(FolderManageMode parentEffective) =>
    parentEffective == FolderManageMode.managedRecursive
    ? FolderManageMode.managedRecursive
    : FolderManageMode.opaque;

/// 그 모드의 폴더가 **직속 내용을 인덱싱하는지**(관리/재귀 관리면 true).
bool indexesContents(FolderManageMode mode) =>
    mode == FolderManageMode.managed ||
    mode == FolderManageMode.managedRecursive;

/// 직속 내용을 인덱싱하는 폴더 경로들의 집합. 루트가 인덱싱하면 빈 문자열('')도
/// 포함한다. 어떤 노드가 인덱싱 범위 안인지(=부모가 내용을 인덱싱하는지) 판정해,
/// 범위 밖으로 밀려난 노드(연결 끊김 포함)를 정리하는 데 쓴다.
Set<String> indexingFolderPaths(
  Iterable<FileNode> nodes,
  FolderManageMode rootMode,
) {
  final resolved = resolveManageModes(nodes, rootMode);
  return {
    if (indexesContents(rootMode)) '',
    for (final entry in resolved.entries)
      if (indexesContents(entry.value)) entry.key,
  };
}

/// 루트 기준 상대 경로의 부모 경로. 최상위면 빈 문자열(루트).
String parentDirPath(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i);
}

/// 폴더별 effective 관리 모드(상속 반영)를 계산한다. [rootMode]는 루트의 모드.
///
/// [nodes] 중 폴더만 본다. 각 폴더의 override(null=상속)와 부모 체인으로 결정한다.
Map<String, FolderManageMode> resolveManageModes(
  Iterable<FileNode> nodes,
  FolderManageMode rootMode,
) {
  final overrides = <String, FolderManageMode?>{
    for (final n in nodes)
      if (n.isDirectory) n.path: n.manageMode,
  };
  final resolved = <String, FolderManageMode>{};

  FolderManageMode compute(String path) {
    final memo = resolved[path];
    if (memo != null) return memo;
    final ov = overrides[path];
    final FolderManageMode eff;
    if (ov != null) {
      eff = ov;
    } else {
      final parent = parentDirPath(path);
      final parentEff = parent.isEmpty ? rootMode : compute(parent);
      eff = inheritedChildMode(parentEff);
    }
    resolved[path] = eff;
    return eff;
  }

  for (final path in overrides.keys) {
    compute(path);
  }
  return resolved;
}

/// [newRootMode]와 새 폴더 override 맵([newOverrides], 폴더 경로→override)에서,
/// 현재 [nodes] 중 **더 이상 인덱싱되지 않을 노드의 경로**를 돌려준다.
///
/// 어떤 노드는 그 부모 폴더가 직속 내용을 인덱싱할 때만(=부모 체인이 모두
/// managed/managedRecursive) 인덱싱된다. 관리 범위를 줄이는 전환(불투명/재귀 끄기)
/// 시 사라질 하위(태그 포함)를 경고·정리하는 데 쓴다.
Set<String> droppedNodePaths(
  List<FileNode> nodes,
  FolderManageMode newRootMode,
  Map<String, FolderManageMode?> newOverrides,
) {
  final resolvedMemo = <String, FolderManageMode>{};
  final indexesMemo = <String, bool>{};
  final indexedMemo = <String, bool>{};

  FolderManageMode resolved(String path) {
    final memo = resolvedMemo[path];
    if (memo != null) return memo;
    final ov = newOverrides[path];
    final FolderManageMode eff;
    if (ov != null) {
      eff = ov;
    } else {
      final parent = parentDirPath(path);
      final parentEff = parent.isEmpty ? newRootMode : resolved(parent);
      eff = inheritedChildMode(parentEff);
    }
    resolvedMemo[path] = eff;
    return eff;
  }

  // indexed ↔ indexesContents는 서로를 참조하므로 late로 선언해 묶는다.
  late final bool Function(String) indexed;

  bool indexesContents(String dirPath) {
    final memo = indexesMemo[dirPath];
    if (memo != null) return memo;
    final bool res;
    if (dirPath.isEmpty) {
      res =
          newRootMode == FolderManageMode.managed ||
          newRootMode == FolderManageMode.managedRecursive;
    } else if (!indexed(dirPath)) {
      res = false;
    } else {
      final eff = resolved(dirPath);
      res =
          eff == FolderManageMode.managed ||
          eff == FolderManageMode.managedRecursive;
    }
    indexesMemo[dirPath] = res;
    return res;
  }

  // 노드는 그 부모 폴더가 직속 내용을 인덱싱할 때만 존재한다.
  indexed = (String path) {
    final memo = indexedMemo[path];
    if (memo != null) return memo;
    final res = indexesContents(parentDirPath(path));
    indexedMemo[path] = res;
    return res;
  };

  return {
    for (final n in nodes)
      if (!indexed(n.path)) n.path,
  };
}
