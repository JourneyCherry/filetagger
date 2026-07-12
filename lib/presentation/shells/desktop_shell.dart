import 'package:flutter/material.dart';

import '../commands/app_commands.dart';
import '../commands/command_scope.dart';
import '../widgets/file_toolbar.dart';
import '../widgets/workspace_breadcrumb.dart';
import 'app_menu_bar.dart';
import 'desktop_status_bar.dart';

/// 데스크톱 셸의 골격: 메뉴바 · 주소줄 · 도구모음 · 본문 · 상태표시줄.
///
/// 화면(HomeScreen)은 상태와 명령 구현만 갖고, 창 크롬(chrome)의 배치는 여기서
/// 정한다. 모바일 셸은 같은 [CommandHandlers]를 다른 크롬에 붙인다.
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.handlers,
    required this.workspaceRoot,
    required this.onOpenRecent,
    required this.onSetRootRecursive,
    required this.scanning,
    required this.previewVisible,
    required this.filterBarVisible,
    required this.sortBarVisible,
    required this.groupBarVisible,
    required this.listEditEnabled,
    required this.body,
  });

  final CommandHandlers handlers;

  /// 열린 워크스페이스 경로. null이면 주소줄·도구모음을 감춘다(빈 상태).
  final String? workspaceRoot;

  /// 메뉴바의 '최근 연 폴더' 항목이 부르는 콜백. null이면 목록 전체 비활성.
  final ValueChanged<String>? onOpenRecent;

  /// 메뉴바 '편집'의 루트 폴더 관리 방식 항목이 부르는 콜백. null이면 비활성.
  final ValueChanged<bool>? onSetRootRecursive;

  final bool scanning;
  final bool previewVisible;

  /// 도구모음의 필터·정렬·그룹 조건 줄을 각각 그릴지('보기' 메뉴가 토글).
  final bool filterBarVisible;
  final bool sortBarVisible;
  final bool groupBarVisible;

  /// 목록 행에서 태그를 바로 고칠 수 있는지('보기' 메뉴가 토글). 배치에는 쓰이지
  /// 않고 메뉴의 체크 표시에만 쓴다.
  final bool listEditEnabled;

  /// 목록·프리뷰(워크스페이스 있음) 또는 최근 폴더 목록(빈 상태).
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final root = workspaceRoot;
    return Scaffold(
      body: SafeArea(
        child: CommandScope(
          handlers: handlers,
          child: AppMenuBar(
            handlers: handlers,
            onOpenRecent: onOpenRecent,
            onSetRootRecursive: onSetRootRecursive,
            // '보기'의 토글 명령들은 지금 켜져 있는지를 체크로 보인다.
            commandChecks: {
              AppCommandId.togglePreview: previewVisible,
              AppCommandId.toggleFilterBar: filterBarVisible,
              AppCommandId.toggleSortBar: sortBarVisible,
              AppCommandId.toggleGrouping: groupBarVisible,
              AppCommandId.toggleListEdit: listEditEnabled,
            },
            child: Column(
              children: [
                if (root != null) ...[
                  WorkspaceBreadcrumb(path: root),
                  const Divider(),
                  // 세 줄을 다 숨기면 도구모음 자리 자체를 비워 목록을 넓게 쓴다.
                  if (filterBarVisible || sortBarVisible || groupBarVisible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: FileToolbar(
                        showFilter: filterBarVisible,
                        showSort: sortBarVisible,
                        showGroup: groupBarVisible,
                      ),
                    ),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: body,
                  ),
                ),
                const Divider(),
                DesktopStatusBar(
                  handlers: handlers,
                  scanning: scanning,
                  previewVisible: previewVisible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
