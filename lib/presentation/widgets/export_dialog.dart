import 'package:flutter/material.dart';

import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 내보내기에서 사용자가 정하는 것. 무엇을 내보낼지(대상)는 이미 목록에서 고른
/// 선택이 정하므로, 여기서는 **어떤 태그를 어디까지** 담을지만 받는다.
class ExportOptions {
  const ExportOptions({
    required this.tagIds,
    required this.includeValues,
    required this.includeImages,
  });

  final Set<int> tagIds;
  final bool includeValues;

  /// 커스텀 이미지 태그의 캐시 파일을 함께 내보낼지. 값을 담지 않으면 뜻이 없다.
  final bool includeImages;
}

/// 내보낼 태그와 범위를 고르는 다이얼로그. 취소하면 null.
///
/// [candidates]는 **고른 항목이 실제로 가진** 태그만이다 — 워크스페이스의 태그를 모두
/// 내걸면 고를 것의 태반이 쓸모없다. 기본은 **전체 선택**이라, 덜어낼 것이 없으면
/// 그대로 확인만 누르면 된다.
Future<ExportOptions?> showExportDialog(
  BuildContext context, {
  required List<TagDefinition> candidates,
  required int nodeCount,
}) {
  return showDialog<ExportOptions>(
    context: context,
    builder: (_) => _ExportDialog(candidates: candidates, nodeCount: nodeCount),
  );
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.candidates, required this.nodeCount});

  final List<TagDefinition> candidates;
  final int nodeCount;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late Set<int> _selected = {
    for (final d in widget.candidates)
      if (d.id != null) d.id!,
  };
  bool _includeValues = true;
  bool _includeImages = true;

  /// 이미지 태그가 후보에 없으면 '이미지 포함'을 낼 이유가 없다.
  bool get _hasImageTag =>
      widget.candidates.any((d) => d.valueType == TagValueType.image);

  @override
  Widget build(BuildContext context) {
    final all = {
      for (final d in widget.candidates)
        if (d.id != null) d.id!,
    };
    return AlertDialog(
      title: const Text('태그 내보내기'),
      content: dialogContentBox(
        context,
        width: 460,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.nodeCount}개 항목의 태그를 요청함 파일 하나로 내보냅니다. '
              '받는 쪽은 그 파일을 자기 폴더의 요청함에 넣기만 하면 됩니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('내보낼 태그', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: _selected.length == all.length
                      ? null
                      : () => setState(() => _selected = {...all}),
                  child: const Text('모두'),
                ),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                  child: const Text('해제'),
                ),
              ],
            ),
            Expanded(
              child: widget.candidates.isEmpty
                  ? const Center(child: Text('고른 항목에 붙은 태그가 없습니다.'))
                  : ListView(
                      children: [
                        for (final d in widget.candidates)
                          if (d.id != null) _tagTile(d, d.id!),
                      ],
                    ),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeValues,
              onChanged: (v) => setState(() => _includeValues = v),
              title: const Text('태그값 포함'),
              subtitle: const Text('끄면 태그만 붙고 값은 비어 갑니다.'),
            ),
            // 값을 담지 않으면 이미지도 담을 것이 없다.
            if (_hasImageTag && _includeValues)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeImages,
                onChanged: (v) => setState(() => _includeImages = v),
                title: const Text('이미지 파일 포함'),
                subtitle: const Text('커스텀 썸네일 이미지를 요청 파일 옆에 함께 씁니다.'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  ExportOptions(
                    tagIds: _selected,
                    includeValues: _includeValues,
                    includeImages: _includeImages,
                  ),
                ),
          child: const Text('내보내기…'),
        ),
      ],
    );
  }

  Widget _tagTile(TagDefinition definition, int id) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _selected.contains(id),
      onChanged: (on) => setState(() {
        if (on ?? false) {
          _selected.add(id);
        } else {
          _selected.remove(id);
        }
      }),
      title: Align(
        alignment: Alignment.centerLeft,
        child: TagChip(definition: definition),
      ),
    );
  }
}
