import 'package:flutter/material.dart';

import '../../domain/entities/system_tag.dart';
import '../commands/app_commands.dart';
import '../help_topics.dart';
import '../tag_visuals.dart';
import '../usage_tips.dart';
import 'dialog_utils.dart';
import 'tag_chip.dart';

/// 도움말 다이얼로그. 성격이 다른 넷을 탭으로 나눠 담는다([HelpTab]).
///
/// 한 번 읽는 산문(사용법·사용 팁)과 되풀이해 찾는 레퍼런스(기능과 단축키·시스템 태그)를
/// 갈라 두어, 표를 보려고 설명을 스크롤해 지나지 않게 한다. 그래도 **다이얼로그는 하나**다 —
/// 찾는 내용이 어느 범주인지 모르고 여는 경우가 많아, 열고 나서 탭으로 옮겨 다닐 수 있어야
/// 한다. 메뉴는 [initial]로 원하는 탭을 바로 열어 발견성을 대신 채운다.
///
/// 어느 탭도 워크스페이스 상태를 읽지 않는다 — 폴더를 열기 전에도 봐야 하기 때문이다.
Future<void> showHelpDialog(
  BuildContext context, {
  HelpTab initial = HelpTab.howTo,
}) => showDialog<void>(
  context: context,
  builder: (_) => _HelpDialog(initial: initial),
);

class _HelpDialog extends StatelessWidget {
  const _HelpDialog({required this.initial});

  final HelpTab initial;

  Widget _tabView(HelpTab tab) => switch (tab) {
    HelpTab.howTo => const _HowToTab(),
    HelpTab.tips => const _TipsTab(),
    HelpTab.shortcuts => const _ShortcutsTab(),
    HelpTab.systemTags => const _SystemTagTab(),
  };

  @override
  Widget build(BuildContext context) {
    return escDismissible(
      context,
      DefaultTabController(
        length: HelpTab.values.length,
        initialIndex: initial.index,
        child: AlertDialog(
          title: Text(commandOf(AppCommandId.help).label),
          // 탭 막대가 제목과 본문 사이에 붙도록 본문 위쪽 여백을 걷어낸다.
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: dialogContentBox(
            context,
            width: 560,
            height: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  // 탭이 넷이라 좁은 창에서는 이름이 눌린다. 늘려 두고 가로로 넘긴다.
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (final tab in HelpTab.values) Tab(text: tab.label),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [for (final tab in HelpTab.values) _tabView(tab)],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 사용법 ──

class _HowToTab extends StatelessWidget {
  const _HowToTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final topic in helpTopics) ...[
          _IconParagraph(
            icon: topic.icon,
            title: topic.title,
            body: topic.body,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── 기능과 단축키 ──

class _ShortcutsTab extends StatelessWidget {
  const _ShortcutsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text(
          '메뉴·버튼으로 부를 수 있는 조작과, 있다면 그 단축키입니다. 지금 할 수 없는 '
          '조작(고른 항목이 없을 때의 태그 부여 등)도 함께 싣습니다.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final group in helpCommandGroups) ...[
          _CommandGroupSection(group: group),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _CommandGroupSection extends StatelessWidget {
  const _CommandGroupSection({required this.group});

  final HelpCommandGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = group.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(note, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 6),
        for (final id in group.commands) _commandRow(theme, commandOf(id)),
      ],
    );
  }

  Widget _commandRow(ThemeData theme, AppCommand command) {
    final shortcut = command.shortcut;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: command.icon == null
                ? null
                : Icon(
                    command.icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
          Expanded(child: Text(command.label, style: theme.textTheme.bodyMedium)),
          if (shortcut != null) ShortcutBadge(label: shortcutLabel(shortcut)),
        ],
      ),
    );
  }
}

// ── 사용 팁 ──

class _TipsTab extends StatelessWidget {
  const _TipsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: usageTips.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, i) => _TipTile(tip: usageTips[i]),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.tip});

  final UsageTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final command = tip.command == null ? null : commandOf(tip.command!);
    final shortcut = command?.shortcut;
    return _IconParagraph(
      icon: tip.icon,
      title: tip.title,
      body: tip.body,
      footer: command == null
          ? null
          : Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '관련 조작: ${command.label}',
                  style: theme.textTheme.labelSmall,
                ),
                if (shortcut != null)
                  ShortcutBadge(label: shortcutLabel(shortcut)),
              ],
            ),
    );
  }
}

// ── 시스템 태그 ──

class _SystemTagTab extends StatelessWidget {
  const _SystemTagTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text(systemTagOverview, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        for (final tag in SystemTag.values) ...[
          _SystemTagTile(tag: tag),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _SystemTagTile extends StatelessWidget {
  const _SystemTagTile({required this.tag});

  final SystemTag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TagChip(definition: tag.definition),
            const SizedBox(width: 8),
            Text(
              tagValueTypeLabel(tag.valueType),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          systemTagDescription(tag),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── 공통 조각 ──

/// 아이콘 + 제목 + 본문(+ 꼬리말) 한 문단. 사용법·팁 탭이 같은 모양을 쓴다.
class _IconParagraph extends StatelessWidget {
  const _IconParagraph({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 12),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 6), footer!],
            ],
          ),
        ),
      ],
    );
  }
}

/// 단축키를 키캡처럼 감싸 보이는 작은 표식.
class ShortcutBadge extends StatelessWidget {
  const ShortcutBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
