import 'package:flutter/material.dart';

import '../../domain/entities/tag_definition.dart';

/// 태그를 이름으로 검색·선택하는 편집 가능 콤보박스(텍스트박스+드롭다운).
///
/// Flutter 기본 [DropdownMenu]를 그대로 쓴다(C#의 `DropDownStyle=DropDown`,
/// 웹의 editable combobox에 해당). `enableFilter`로 입력에 따라 후보를 걸러
/// 위/아래 방향키로 이동해 Enter로 선택한다. 태그 종류가 많아져도 이름 일부로
/// 걸러 고를 수 있다. 필터·정렬·부여 다이얼로그가 이 위젯을 공유한다.
///
/// (참고: 입력 중 커서가 끝으로 튀고 방향키 이동이 안 되던 현상은 구버전
/// DropdownMenu의 필터 처리 버그로, Flutter 상향과 함께 해소됐다.)
class TagPicker extends StatelessWidget {
  const TagPicker({
    super.key,
    required this.definitions,
    required this.selectedId,
    required this.onSelected,
  });

  final List<TagDefinition> definitions;

  /// 현재 선택된 태그 정의 id(편집 시 초기 표시용). 미선택이면 null.
  final int? selectedId;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      initialSelection: selectedId,
      requestFocusOnTap: true,
      enableFilter: true,
      enableSearch: true,
      expandedInsets: EdgeInsets.zero,
      leadingIcon: const Icon(Icons.search),
      label: const Text('태그'),
      hintText: '태그 이름 검색',
      menuHeight: 320,
      dropdownMenuEntries: [
        for (final d in definitions)
          if (d.id != null) DropdownMenuEntry(value: d.id!, label: d.name),
      ],
      onSelected: (v) {
        if (v != null) onSelected(v);
      },
    );
  }
}
