import 'package:flutter/material.dart';

import 'dialog_utils.dart';

/// 키워드 다이얼로그 본문의 폭(원하는 값 — 좁은 화면에선 깎인다).
const double _keywordDialogWidth = 360;

/// 키워드의 이름을 받는다. 취소하거나 빈 이름이면 null.
///
/// 만들기와 편집이 같은 다이얼로그를 쓴다 — 키워드는 **이름이 전부**라 둘이 받는
/// 것이 같다(부연 정보는 본문이 아니라 태그로 붙는다). 이름 규칙 위반·중복은
/// 저장소가 판정하므로 여기선 막지 않고, 확정 버튼만 빈 이름에서 잠근다.
Future<String?> showKeywordDialog(
  BuildContext context, {
  String initialName = '',
  required String title,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _KeywordDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

class _KeywordDialog extends StatefulWidget {
  const _KeywordDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_KeywordDialog> createState() => _KeywordDialogState();
}

class _KeywordDialogState extends State<_KeywordDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: dialogContentBox(
        context,
        width: _keywordDialogWidth,
        child: TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '이름',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
          // 확정 버튼의 잠금이 입력에 따라 풀리도록.
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// 키워드를 지우기 전 확인을 받는다. 사용자가 만들어 둔 자산이고 그 키워드에 붙은
/// 태그와 그것을 가리키던 링크까지 영향을 받으므로, 조건 프리셋 삭제와 같은 톤으로
/// 한 번 묻는다.
Future<bool> confirmKeywordDelete(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('키워드 삭제'),
      content: Text("'$name' 키워드와 그 태그를 지웁니다. 되돌릴 수 없습니다."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  return result ?? false;
}
