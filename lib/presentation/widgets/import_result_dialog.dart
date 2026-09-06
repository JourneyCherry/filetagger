import 'package:flutter/material.dart';

import '../../domain/entities/external_tag_command.dart';
import '../../domain/usecases/apply_external_commands.dart';
import '../../l10n/app_localizations.dart';
import 'dialog_utils.dart';

/// 가져오기 결과를 보인다.
///
/// **적용된 것은 세기만 하고, 적용되지 않은 것만 펼친다.** 잘된 일을 줄줄이 늘어놓아도
/// 읽을 이유가 없고, 사용자가 손댈 수 있는 것은 서지 못한 항목뿐이다.
///
/// 보류와 거부를 한 목록에 두되 사유 자리에서 가른다 — 둘 다 "안 붙었다"는 점은 같지만
/// 보류는 스캔 뒤 다시 가져오면 서고, 거부는 파일이나 태그를 고쳐야 선다.
Future<void> showImportResultDialog(
  BuildContext context, {
  required List<ExternalCommandResult> results,
  required int unreadable,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _ImportResultDialog(results: results, unreadable: unreadable),
  );
}

class _ImportResultDialog extends StatelessWidget {
  const _ImportResultDialog({required this.results, required this.unreadable});

  final List<ExternalCommandResult> results;

  /// 명령으로 **읽어 내지도 못한** 항목 수. 판정이 아니라 형식 오류라 목록에 담지
  /// 않고 수만 알린다 — 무엇이 어긋났는지는 콘솔의 가져오기가 자세히 말한다.
  final int unreadable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final held = results.whereType<CommandHeld>().length;
    final rejected = results.whereType<CommandRejected>().length;
    final problems = [
      for (final result in results)
        if (result is! CommandApplied) result,
    ];

    return AlertDialog(
      title: Text(l10n.importTitle),
      content: dialogContentBox(
        context,
        width: 520,
        height: problems.isEmpty ? null : 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.importSummary(
                results.length - held - rejected,
                held,
                rejected,
              ),
              style: theme.textTheme.titleSmall,
            ),
            if (unreadable > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.importUnreadable(unreadable),
                style: theme.textTheme.bodyMedium,
              ),
              Text(l10n.importUnreadableHint, style: theme.textTheme.bodySmall),
            ],
            if (held > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.importHeldHint, style: theme.textTheme.bodySmall),
            ],
            if (problems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.importItemsToFix, style: theme.textTheme.titleSmall),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    for (final problem in problems) _row(context, problem),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, ExternalCommandResult result) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final command = result.command;
    final value = command.value;
    final reason = switch (result) {
      CommandHeld() => l10n.importHeldLabel,
      CommandRejected(:final reason) => importReasonLabel(l10n, reason),
      CommandApplied() => '',
    };
    // 해석기가 덧붙인 세부 갈래. 사유만으로는 짚이지 않는 자리(같은 사유 안에서
    // 무엇이 어긋났는지)를 말하므로, 가려 두면 사용자가 무엇을 고쳐야 할지 알 수 없다.
    // **갈래 이름을 그대로 보인다** — 순수 Dart 계층이 낸 것이라 문장이 없다.
    final detail = result is CommandRejected
        ? failureDetailLabel(result)
        : null;
    // 보류는 사고가 아니라 "아직"이라, 거부와 같은 빨강으로 칠하지 않는다.
    final color = result is CommandRejected
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      dense: true,
      isThreeLine: detail != null,
      contentPadding: EdgeInsets.zero,
      title: Text(command.targetPath, style: theme.textTheme.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value == null ? command.tagName : '${command.tagName} = $value',
            style: theme.textTheme.bodySmall,
          ),
          if (detail != null)
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
        ],
      ),
      trailing: Text(
        reason,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// 거부 사유의 표시 문구.
///
/// 사유의 **갈래**는 여기서 번역하고, 해석기가 덧붙인 설명은 그 아래 그대로 보인다 —
/// 갈래만으로는 "어느 값이 어긋났는지"를 알 수 없기 때문이다. 그 설명은 아직 원문
/// (템플릿 언어)이며, 번역이 필요해지면 사유별 자리표시자로 다시 세울 자리다.
/// 거부에 딸린 세부 갈래 한 줄. 세부가 없으면(사유가 이미 말한 것이면) null이다.
String? failureDetailLabel(CommandRejected rejected) {
  final detail = rejected.detail;
  if (detail == null) return null;
  final subject = rejected.subject;
  return subject == null ? detail.name : '${detail.name}: $subject';
}

String importReasonLabel(
  AppLocalizations l10n,
  CommandFailureReason reason,
) => switch (reason) {
  CommandFailureReason.malformed => l10n.importReasonMalformed,
  CommandFailureReason.targetMissing => l10n.importReasonTargetMissing,
  CommandFailureReason.targetNotManaged => l10n.importReasonTargetNotManaged,
  CommandFailureReason.systemTag => l10n.importReasonSystemTag,
  CommandFailureReason.tagMissing => l10n.importReasonTagMissing,
  CommandFailureReason.valueTypeMissing => l10n.importReasonValueTypeMissing,
  CommandFailureReason.valueTypeMismatch => l10n.importReasonValueTypeMismatch,
  CommandFailureReason.invalidValue => l10n.importReasonInvalidValue,
};
