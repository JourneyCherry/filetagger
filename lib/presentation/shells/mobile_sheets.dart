/// 모바일 셸이 다이얼로그 대신 쓰는 바텀시트 모음.
///
/// 데스크톱은 상시 도구모음·우클릭 메뉴로 닿는 조작들을, 모바일에서는 화면
/// 아래에서 올라오는 시트 하나로 모아 엄지 조작 범위 안에 둔다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/folder_manage_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../providers/file_view_provider.dart';
import '../widgets/file_toolbar.dart';

/// 필터·정렬·그룹 도구모음을 시트로 띄운다(모바일에는 상시 도구모음 자리가 없다).
/// 자세히 모드는 자체 헤더 정렬을 쓰고 그룹화를 무시하므로 정렬·그룹 줄을 숨긴다.
Future<void> showFilterSortSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Consumer(
        builder: (context, ref, _) {
          final detail = ref.watch(viewModeProvider) == ViewMode.detail;
          return FileToolbar(showSort: !detail, showGroup: !detail);
        },
      ),
    ),
  );
}

/// 폴더 하나의 관리 방식을 고르는 시트. 고르지 않고 닫으면 null.
///
/// [resolved]는 상속까지 반영한 이 폴더의 실제(effective) 모드다. 데스크톱의
/// 팝업 메뉴와 달리 세 방식을 한 번에 늘어놓아 한 번의 탭으로 고르게 한다.
Future<FolderManageMode?> showFolderManageSheet(
  BuildContext context, {
  required String folderName,
  required FolderManageMode resolved,
}) {
  return showModalBottomSheet<FolderManageMode>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(folderName, overflow: TextOverflow.ellipsis),
          subtitle: const Text('폴더 관리 방식'),
        ),
        const Divider(),
        for (final mode in FolderManageMode.values)
          ListTile(
            leading: Icon(
              mode == resolved
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(_manageModeLabel(mode)),
            subtitle: Text(_manageModeDescription(mode)),
            onTap: () => Navigator.of(sheetContext).pop(mode),
          ),
      ],
    ),
  );
}

String _manageModeLabel(FolderManageMode mode) => switch (mode) {
  FolderManageMode.opaque => '폴더만 관리',
  FolderManageMode.managed => '내부 관리',
  FolderManageMode.managedRecursive => '재귀적으로 관리',
};

String _manageModeDescription(FolderManageMode mode) => switch (mode) {
  FolderManageMode.opaque => '폴더 하나로만 다루고 내부는 감춥니다.',
  FolderManageMode.managed => '직속 내용만 인덱싱합니다.',
  FolderManageMode.managedRecursive => '하위 폴더까지 이어서 인덱싱합니다.',
};

/// 프리뷰를 화면 대부분을 덮는 시트로 띄운다(좁은 폭에서 분할 대신 쓰는 경로).
Future<void> showPreviewSheet(BuildContext context, {required Widget preview}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: preview),
  );
}
