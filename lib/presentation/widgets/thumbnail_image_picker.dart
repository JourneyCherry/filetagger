import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_types.dart';
import '../../data/thumbnails/thumbnail_store.dart';
import '../providers/workspace_provider.dart';

/// 커스텀 이미지 태그값을 정하는 공통 흐름: 외부 이미지 파일을 골라 워크스페이스
/// 캐시에 등록하고 **캐시 키**(저장값)를 돌려준다. 취소하거나 워크스페이스가 없거나
/// 이미지로 인식하지 못하면 null(등록 실패는 스낵바로 알린다).
Future<String?> pickAndRegisterThumbnailImage(
  BuildContext context,
  WidgetRef ref,
) async {
  final root = ref.read(workspaceRootProvider);
  if (root == null) return null;
  final group = XTypeGroup(
    label: '이미지',
    extensions: imageFileExtensions.toList(),
  );
  final file = await openFile(acceptedTypeGroups: [group]);
  if (file == null) return null;
  final key = await registerThumbnailImage(root, file.path);
  if (key == null && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이미지를 등록하지 못했습니다.')));
  }
  return key;
}
