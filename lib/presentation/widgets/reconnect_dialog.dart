import 'package:flutter/material.dart';

import '../../domain/entities/file_node.dart';
import 'dialog_utils.dart';

/// 재연결 다이얼로그의 결과.
sealed class ReconnectAction {
  const ReconnectAction();
}

/// 보존 노드의 태그를 [target]으로 옮겨 재연결한다.
class ReconnectToTarget extends ReconnectAction {
  const ReconnectToTarget(this.target);
  final FileNode target;
}

/// 보존을 취소하고 노드(및 그 태그)를 제거한다. 사용자가 새로 태깅하고 싶을 때.
class ReconnectRemove extends ReconnectAction {
  const ReconnectRemove();
}

/// 연결 끊긴(보존된) 노드 [missing]의 원본 파일을 사용자가 직접 고르게 하는
/// 다이얼로그. 후보는 태그가 하나도 없는 실제 노드([candidates])이며, 파일 이름이
/// [missing]과 유사한 순으로 위에 정렬된다. 원본을 고르면 [ReconnectToTarget],
/// 보존 취소를 누르면 [ReconnectRemove], 취소하면 null을 반환한다.
Future<ReconnectAction?> showReconnectDialog(
  BuildContext context, {
  required FileNode missing,
  required List<FileNode> candidates,
}) {
  return showDialog<ReconnectAction>(
    context: context,
    builder: (context) =>
        _ReconnectDialog(missing: missing, candidates: candidates),
  );
}

/// [candidates]를 파일 이름이 [targetName]과 유사한 순(편집 거리 오름차순,
/// 동률은 경로순)으로 정렬해 돌려준다. 순수 함수라 단독 테스트가 가능하다.
List<FileNode> sortCandidatesByNameSimilarity(
  String targetName,
  List<FileNode> candidates,
) {
  final target = targetName.toLowerCase();
  final scored = [
    for (final node in candidates)
      (node: node, distance: _levenshtein(target, node.name.toLowerCase())),
  ]..sort((a, b) {
      final byDistance = a.distance.compareTo(b.distance);
      return byDistance != 0 ? byDistance : a.node.path.compareTo(b.node.path);
    });
  return [for (final e in scored) e.node];
}

/// 두 문자열의 Levenshtein 편집 거리(작을수록 유사).
int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

class _ReconnectDialog extends StatefulWidget {
  const _ReconnectDialog({required this.missing, required this.candidates});

  final FileNode missing;
  final List<FileNode> candidates;

  @override
  State<_ReconnectDialog> createState() => _ReconnectDialogState();
}

class _ReconnectDialogState extends State<_ReconnectDialog> {
  late final List<FileNode> _sorted =
      sortCandidatesByNameSimilarity(widget.missing.name, widget.candidates);
  String _query = '';

  List<FileNode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sorted;
    return _sorted.where((n) => n.path.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return escDismissible(
      context,
      AlertDialog(
        title: const Text('원본 파일 찾기'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "'${widget.missing.name}'의 태그를 옮길 원본 파일을 고르세요. "
                '이름이 비슷한 후보가 위에 옵니다. 원본이 없으면 "보존 취소"로 '
                '태그를 제거할 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '경로로 검색',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: widget.candidates.isEmpty
                    ? const Text('연결할 수 있는(태그 없는) 후보 노드가 없습니다.')
                    : filtered.isEmpty
                        ? const Text('검색 결과가 없습니다.')
                        : Scrollbar(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final node = filtered[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(node.isDirectory
                                      ? Icons.folder
                                      : Icons.insert_drive_file_outlined),
                                  title: Text(node.name),
                                  subtitle: Text(node.path),
                                  onTap: () => Navigator.of(context)
                                      .pop(ReconnectToTarget(node)),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () =>
                Navigator.of(context).pop(const ReconnectRemove()),
            child: const Text('보존 취소(제거)'),
          ),
        ],
      ),
    );
  }
}
