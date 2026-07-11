import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/presentation/widgets/folder_manage_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('불투명 → 내부 관리로 바꾼다', () {
    expect(
      nextManageMode(FolderManageMode.opaque, FolderManageAction.managed),
      FolderManageMode.managed,
    );
  });

  test('이미 관리 계열이면 내부 관리 라디오는 아무 것도 바꾸지 않는다', () {
    expect(
      nextManageMode(FolderManageMode.managed, FolderManageAction.managed),
      isNull,
    );
    expect(
      nextManageMode(
        FolderManageMode.managedRecursive,
        FolderManageAction.managed,
      ),
      isNull,
    );
  });

  test('관리 계열 → 불투명으로 바꾸고, 이미 불투명이면 그대로 둔다', () {
    expect(
      nextManageMode(
        FolderManageMode.managedRecursive,
        FolderManageAction.opaque,
      ),
      FolderManageMode.opaque,
    );
    expect(
      nextManageMode(FolderManageMode.opaque, FolderManageAction.opaque),
      isNull,
    );
  });

  test('재귀 토글은 관리 계열 안에서만 오간다', () {
    expect(
      nextManageMode(
        FolderManageMode.managed,
        FolderManageAction.toggleRecursive,
      ),
      FolderManageMode.managedRecursive,
    );
    expect(
      nextManageMode(
        FolderManageMode.managedRecursive,
        FolderManageAction.toggleRecursive,
      ),
      FolderManageMode.managed,
    );
  });

  test('불투명일 땐 재귀 토글이 의미 없다', () {
    expect(
      nextManageMode(
        FolderManageMode.opaque,
        FolderManageAction.toggleRecursive,
      ),
      isNull,
    );
  });
}
