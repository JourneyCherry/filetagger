import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/view_mode.dart';
import '../providers/file_view_provider.dart';

/// 파일 목록 보기 모드(목록/아이콘/자세히)를 고르는 세그먼트 버튼.
///
/// 도구모음 칩처럼 [viewSettingsProvider]를 직접 읽고 쓴다(명령 카탈로그를 거치지
/// 않는다). 데스크톱 크롬과 모바일 앱바가 함께 쓰며, 좁은 자리(모바일 앱바)에서는
/// 아이콘만 보이도록 라벨을 접는다.
class ViewModeSelector extends ConsumerWidget {
  const ViewModeSelector({super.key, this.showLabels = true});

  /// 각 세그먼트에 이름을 함께 보일지. 좁은 자리에서는 false로 두어 아이콘만 낸다.
  final bool showLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(viewModeProvider);
    return SegmentedButton<ViewMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final entry in _entries)
          ButtonSegment(
            value: entry.mode,
            icon: Icon(entry.icon),
            label: showLabels ? Text(entry.label) : null,
            tooltip: entry.label,
          ),
      ],
      selected: {mode},
      onSelectionChanged: (s) =>
          ref.read(viewSettingsProvider.notifier).updateViewMode(s.first),
    );
  }
}

/// 보기 모드 하나의 표시 정보(라벨·아이콘). 세그먼트와 메뉴가 함께 참조한다.
class ViewModeChoice {
  const ViewModeChoice(this.mode, this.label, this.icon);

  final ViewMode mode;
  final String label;
  final IconData icon;
}

/// 보기 모드 표시 정보의 단일 출처(세그먼트·메뉴 라디오가 같은 라벨·아이콘을 쓴다).
const List<ViewModeChoice> viewModeChoices = [
  ViewModeChoice(ViewMode.list, '목록', Icons.view_list_outlined),
  ViewModeChoice(ViewMode.icon, '아이콘', Icons.grid_view_outlined),
  ViewModeChoice(ViewMode.detail, '자세히', Icons.view_column_outlined),
];

const List<ViewModeChoice> _entries = viewModeChoices;
