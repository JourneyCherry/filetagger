import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/file_types.dart';
import '../../domain/entities/file_node.dart';
import '../providers/thumbnail_provider.dart';
import '../providers/workspace_provider.dart';

/// 노드의 썸네일을 그린다. 이미지 파일은 자기 자신, 폴더는 하위 이미지들을 겹쳐
/// 쌓아 보이고, 보일 이미지가 없거나 로드에 실패하면 기본 아이콘으로 폴백한다.
/// 목록 타일과 프리뷰 창이 함께 쓴다.
class FileThumbnail extends ConsumerWidget {
  const FileThumbnail({
    super.key,
    required this.node,
    this.dimension = 40,
    this.expand = false,
    this.fit = BoxFit.cover,
  });

  final FileNode node;

  /// 고정 정사각형 한 변 길이. [expand]가 true면 무시하고 부모를 채운다.
  final double dimension;

  /// true면 부모 영역을 채우도록 늘어난다(프리뷰 창의 큰 미리보기용).
  final bool expand;

  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(workspaceRootProvider);
    final folderThumbnails = ref.watch(folderThumbnailIndexProvider);
    final rels = root == null
        ? const <String>[]
        : resolveThumbnailRelPaths(node, folderThumbnails);

    if (root == null || rels.isEmpty) return _sized(_fallback(context));

    final absolute = [
      for (final rel in rels) p.joinAll([root, ...rel.split('/')]),
    ];

    final Widget content = absolute.length == 1
        ? _single(context, absolute.first)
        : _StackedThumbnail(absolutePaths: absolute);

    return _sized(
      ClipRRect(borderRadius: BorderRadius.circular(6), child: content),
    );
  }

  /// 고정 크기 모드면 정사각형으로, expand면 부모를 채우도록 감싼다.
  Widget _sized(Widget child) {
    if (expand) return SizedBox.expand(child: child);
    return SizedBox(width: dimension, height: dimension, child: child);
  }

  Widget _single(BuildContext context, String path) {
    final file = File(path);
    if (expand) {
      // 프리뷰: 원본을 그대로 디코딩해 로드되는 즉시 표시한다(저해상도 단계 없음).
      // gaplessPlayback을 쓰지 않아 다른 파일을 선택하면 이전 이미지를 즉시 비우고,
      // 새 이미지가 준비될 때까지 뒤의 빈 배경이 보인다.
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, _, __) => _fallback(context),
      );
    }
    // 목록 썸네일: 작은 타일이라 표시 크기에 맞춰 디코딩한다(원본 전체 디코딩은
    // 메모리·속도 낭비). 프리뷰 화질과는 무관하다.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      file,
      fit: fit,
      cacheWidth: (dimension * dpr).round(),
      errorBuilder: (context, _, __) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final IconData icon;
    Color? color;
    if (node.isMissing) {
      icon = Icons.link_off;
      color = scheme.error;
    } else if (node.isDirectory) {
      icon = Icons.folder;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    if (expand) return Center(child: Icon(icon, color: color, size: 72));
    return Icon(icon, color: color, size: dimension * 0.6);
  }
}

/// 폴더 하위 이미지 여러 장을 살짝 회전·이동시켜 입체적으로 쌓아 보여준다.
/// 맨 위 장은 똑바로 놓아 대표처럼 보이게 한다. 한 장이 실패하면 그 자리만 비운다.
class _StackedThumbnail extends StatelessWidget {
  const _StackedThumbnail({required this.absolutePaths});

  final List<String> absolutePaths;

  /// 아래에서 위로 쌓이는 층의 회전각(라디안)과 상대 이동(박스 크기 대비 비율).
  /// 마지막(맨 위) 층은 똑바로·가운데.
  static const List<double> _angles = [-0.15, 0.12, 0.0];
  static const List<Offset> _offsets = [
    Offset(-0.10, 0.07),
    Offset(0.11, -0.05),
    Offset(0, 0),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final layers = absolutePaths.take(_angles.length).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide.isFinite
            ? constraints.biggest.shortestSide
            : 40.0;
        final photo = side * 0.72;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < layers.length; i++)
              Transform.translate(
                offset: _offsets[i] * side,
                child: Transform.rotate(
                  angle: _angles[i],
                  child: _photo(scheme, layers[i], photo, dpr),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _photo(ColorScheme scheme, String path, double size, double dpr) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.surface, width: size * 0.045),
        borderRadius: BorderRadius.circular(size * 0.06),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: (size * dpr).round(),
        errorBuilder: (context, _, __) =>
            ColoredBox(color: scheme.surfaceContainerHighest),
      ),
    );
  }
}
