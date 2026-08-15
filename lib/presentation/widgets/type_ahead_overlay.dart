import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/type_ahead.dart';

/// 빠른 탐색으로 이어 친 글자를 목록 위에 띄워 알린다(검색 중이 아니면 아무것도
/// 덧대지 않는다).
///
/// 표시가 필요한 이유는 **아무 반응이 없을 때를 가리기 위함**이다 — 맞는 항목이 없어
/// 커서가 그대로인 것과, 글자가 아예 들어가지 않은 것(입력기가 조합 중일 때 등)은
/// 커서만 봐서는 구별되지 않는다. 세 보기 모드가 한 검색어를 나눠 쓰므로 표시도
/// 목록 자리 하나에 둔다.
class TypeAheadOverlay extends ConsumerWidget {
  const TypeAheadOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(typeAheadProvider);
    // 검색어가 없을 때도 같은 자리 구조를 유지한다 — 감싸기를 넣었다 뺐다 하면 목록이
    // 다른 자리로 옮겨진 것으로 보여 통째로 다시 세워지고(스크롤 위치·드릴인 위치가
    // 첫 글자에 사라진다), passthrough는 제약을 그대로 넘겨 배치도 바뀌지 않는다.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        // 목록 조작을 가로막지 않도록 클릭을 통과시킨다(표시 전용).
        if (query.isNotEmpty)
          Positioned(
            right: 8,
            bottom: 8,
            child: IgnorePointer(child: _badge(context, query)),
          ),
      ],
    );
  }

  Widget _badge(BuildContext context, String query) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.inverseSurface,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 16, color: scheme.onInverseSurface),
            const SizedBox(width: 6),
            Text(query, style: TextStyle(color: scheme.onInverseSurface)),
          ],
        ),
      ),
    );
  }
}
