import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_types.dart';
import '../../domain/entities/workspace_view_settings.dart';
import '../providers/file_view_provider.dart';

/// 목록 옆에 프리뷰를 나란히 둘 만큼 창이 넓은지.
///
/// 좁으면 셸이 분할 대신 프리뷰를 시트로 띄운다. 판단 기준은 플랫폼이 아니라
/// **폭**이다(태블릿 가로, 창을 줄인 데스크톱이 같은 규칙을 따른다).
bool prefersSplitPane(double width) => width >= _splitPaneMinWidth;

const double _splitPaneMinWidth = 720;

/// 목록과 프리뷰를 분할선으로 나눠 배치하는, 셸에 독립적인 뷰.
///
/// 가로로 넓으면 프리뷰를 왼쪽에, 세로로 길면 위쪽에 둔다. 분할선을 드래그해
/// 비율을 바꾸면 놓는 순간 보기 설정에 저장한다.
class PreviewSplitView extends ConsumerStatefulWidget {
  const PreviewSplitView({
    super.key,
    required this.list,
    required this.preview,
  });

  final Widget list;
  final Widget preview;

  @override
  ConsumerState<PreviewSplitView> createState() => _PreviewSplitViewState();
}

class _PreviewSplitViewState extends ConsumerState<PreviewSplitView> {
  /// 드래그하는 동안의 임시 비율. 드래그가 끝나면 저장하고 null로 되돌린다
  /// (그 뒤엔 저장된 값을 쓴다).
  double? _ratioDrag;

  @override
  Widget build(BuildContext context) {
    final ratio = _ratioDrag ?? ref.watch(viewSettingsProvider).previewRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = preferHorizontalPreview(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final total = horizontal ? constraints.maxWidth : constraints.maxHeight;
        final paneExtent = total * ratio;
        final handle = _buildDragHandle(horizontal: horizontal, total: total);
        if (horizontal) {
          return Row(
            children: [
              SizedBox(width: paneExtent, child: widget.preview),
              handle,
              Expanded(child: widget.list),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(height: paneExtent, child: widget.preview),
            handle,
            Expanded(child: widget.list),
          ],
        );
      },
    );
  }

  /// 프리뷰와 목록 사이의 분할선. 커서를 리사이즈 모양으로 바꿔 잡을 수 있음을 알린다.
  Widget _buildDragHandle({required bool horizontal, required double total}) {
    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          if (total <= 0) return;
          final delta = horizontal ? details.delta.dx : details.delta.dy;
          final base =
              _ratioDrag ?? ref.read(viewSettingsProvider).previewRatio;
          setState(() {
            _ratioDrag = (base + delta / total).clamp(
              kPreviewRatioMin,
              kPreviewRatioMax,
            );
          });
        },
        onPanEnd: (_) {
          final ratio = _ratioDrag;
          if (ratio != null) {
            ref.read(viewSettingsProvider.notifier).updatePreviewRatio(ratio);
          }
          setState(() => _ratioDrag = null);
        },
        child: horizontal
            ? const VerticalDivider(width: 10, thickness: 1)
            : const Divider(height: 10, thickness: 1),
      ),
    );
  }
}
