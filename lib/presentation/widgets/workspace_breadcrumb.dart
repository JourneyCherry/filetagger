import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// 현재 워크스페이스의 경로를 구간별로 보여 주는 주소줄.
///
/// 구간은 **표시 전용**이다 — 상위 폴더를 누르면 그 폴더가 새 워크스페이스로 열리며
/// `.filetagger/`가 생기므로, 폴더 전환은 '폴더 열기'라는 명시적 조작에만 맡긴다.
class WorkspaceBreadcrumb extends StatelessWidget {
  const WorkspaceBreadcrumb({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segments = p.split(path);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // 경로가 길면 현재 폴더(끝)가 보이도록 끝에서부터 채운다.
              reverse: true,
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0)
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: scheme.outline,
                      ),
                    Text(
                      segments[i],
                      style: i == segments.length - 1
                          ? textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
