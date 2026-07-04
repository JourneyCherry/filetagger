import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/tag_definition.dart';
import '../../domain/entities/tag_value_type.dart';
import '../tag_visuals.dart';

/// 값 입력 결과. 취소 시 null이 반환되며, 저장 시 [value](비었으면 null)를
/// 감싸 돌려주어 "값 없음으로 저장"과 "취소"를 구분한다.
class TagValueResult {
  const TagValueResult(this.value);
  final String? value;
}

/// 태그 값 유형에 맞는 입력을 띄워 값을 받는다. label은 값이 없어 즉시 통과.
///
/// text/number는 텍스트 다이얼로그, date는 네이티브 날짜 선택기를 쓴다.
Future<TagValueResult?> promptTagValue(
  BuildContext context,
  TagDefinition definition, {
  String? initial,
}) async {
  switch (definition.valueType) {
    case TagValueType.label:
      return const TagValueResult(null);
    case TagValueType.date:
      final init = DateTime.tryParse(initial ?? '') ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: DateTime(1970),
        lastDate: DateTime(2100),
      );
      if (picked == null) return null;
      return TagValueResult(dateToStoredValue(picked));
    case TagValueType.text:
    case TagValueType.number:
      return showDialog<TagValueResult>(
        context: context,
        builder: (_) => _TextValueDialog(definition: definition, initial: initial),
      );
  }
}

class _TextValueDialog extends StatefulWidget {
  const _TextValueDialog({required this.definition, this.initial});

  final TagDefinition definition;
  final String? initial;

  @override
  State<_TextValueDialog> createState() => _TextValueDialogState();
}

class _TextValueDialogState extends State<_TextValueDialog> {
  /// 숫자를 입력하지 않았을 때 채우는 기본값(빈 값 방지). 값 자체는 여기서만 둔다.
  static const String _numberDefault = '0';

  late final TextEditingController _controller;
  String? _error;

  bool get _isNumber => widget.definition.valueType == TagValueType.number;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (_isNumber) {
      // 미입력 시 기본값으로 채우고, 입력했으면 숫자만 허용한다.
      if (text.isEmpty) {
        Navigator.of(context).pop(const TagValueResult(_numberDefault));
        return;
      }
      if (num.tryParse(text) == null) {
        setState(() => _error = '숫자를 입력해주세요.');
        return;
      }
      Navigator.of(context).pop(TagValueResult(text));
      return;
    }
    // 텍스트는 빈 문자열도 유효한 값으로 저장한다.
    Navigator.of(context).pop(TagValueResult(text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('‘${widget.definition.name}’ 값'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: _isNumber
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        inputFormatters: _isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
            : null,
        decoration: InputDecoration(
          labelText: '값',
          errorText: _error,
          helperText: _isNumber ? '비워두면 기본값이 채워집니다.' : '빈 값도 저장할 수 있습니다.',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _save, child: const Text('확인')),
      ],
    );
  }
}
