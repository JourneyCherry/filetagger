import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_node.dart';
import '../providers/file_node_provider.dart';
import 'dialog_utils.dart';
import 'file_thumbnail.dart';

/// 링크 태그값이 가리킬 **대상 노드를 고르는** 선택기를 띄운다. 고른 노드의 id를
/// 문자열로 돌려주며(저장값), 취소하면 null이다.
///
/// 링크는 저장은 id로, 표시는 대상 이름으로 한다. 후보는 **파일 이름으로 검색**하며,
/// 같은 이름을 구분할 수 있도록 경로를 함께 보인다.
Future<String?> pickLinkTarget(
  BuildContext context, {
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _LinkTargetPicker(initial: initial),
  );
}

class _LinkTargetPicker extends ConsumerStatefulWidget {
  const _LinkTargetPicker({this.initial});

  /// 현재 값(대상 노드 id 문자열). 목록에서 그 노드를 강조한다.
  final String? initial;

  @override
  ConsumerState<_LinkTargetPicker> createState() => _LinkTargetPickerState();
}

class _LinkTargetPickerState extends ConsumerState<_LinkTargetPicker> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 대상은 파일(비디렉토리)만 후보로 낸다 — 폴더는 이미지·링크 대상이 아니다.
    final nodes = [
      for (final n in ref.watch(fileNodesProvider).valueOrNull ?? const [])
        if (!n.isDirectory && n.id != null) n,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? nodes
        : [
            for (final n in nodes)
              if (n.name.toLowerCase().contains(query)) n,
          ];

    final initialId = int.tryParse(widget.initial ?? '');

    return escDismissible(
      context,
      AlertDialog(
        title: const Text('링크 대상 선택'),
        content: SizedBox(
          width: 420,
          height: 480,
          child: Column(
            children: [
              TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '파일 이름으로 검색',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('일치하는 파일이 없습니다.'))
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, i) =>
                            _tile(context, matches[i], initialId),
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
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, FileNode node, int? initialId) {
    final selected = node.id == initialId;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primaryContainer,
      leading: FileThumbnail(node: node, dimension: 40),
      title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(node.path, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => Navigator.of(context).pop(node.id!.toString()),
    );
  }
}
