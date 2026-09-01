import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/entities/file_filter.dart';
import '../../domain/entities/file_node.dart';
import '../../l10n/app_localizations.dart';
import '../common/focus_reveal.dart';
import '../common/navigation_cursor.dart';
import '../common/type_ahead.dart';
import '../providers/file_node_provider.dart';
import '../providers/system_tag_provider.dart';
import '../providers/workspace_provider.dart';
import 'dialog_utils.dart';
import 'file_thumbnail.dart';
import 'filter_query_field.dart';
import 'type_ahead_overlay.dart';

/// 링크 태그값이 가리킬 **대상 노드를 고르는** 선택기를 띄운다. 고른 노드의 id를
/// 문자열로 돌려주며(저장값), 취소하면 null이다.
///
/// 링크는 저장은 id로, 표시는 대상 이름으로 한다. 같은 이름을 구분할 수 있도록 경로를
/// 함께 보인다.
///
/// 후보를 좁히는 것과 짚는 것을 나눈다 — **태그 필터**가 종류를 좁히고(키워드가
/// 종류별로 많이 쌓인 워크스페이스에서 쓴다), 그 안에서 **빠른 탐색**이 커서를 옮긴다.
/// 본창 목록과 같은 손놀림이라 배울 것이 없다. 모바일은 조각 문법도 빠른 탐색도 쓰지
/// 않으므로 이름 검색 칸으로 갈린다.
Future<String?> pickLinkTarget(BuildContext context, {String? initial}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _LinkTargetPicker(initial: initial),
  );
}

/// 선택기가 마지막으로 쓴 태그 필터. 같은 종류의 대상을 연달아 걸 때 매번 다시 치지
/// 않도록 기억하되, 설정에 저장하지 않는다 — 다음 실행에도 남기려면 어느 시점에
/// 지울지를 정해야 하는데, 그 필요가 실제로 서기 전까지는 앱 수명에 묶어 두는 편이
/// 지울 것이 없어 단순하다.
///
/// 관리 폴더를 지켜보는 것은 조건이 담은 태그 정의 id가 **그 폴더의 DB 안에서만**
/// 뜻을 갖기 때문이다. 폴더가 바뀌면 기억을 비워, 남의 폴더에서 친 조건이 엉뚱한
/// 태그를 가리킨 채 목록을 걸러 버리지 않게 한다.
final _rememberedFilterProvider = StateProvider<FileFilter>((ref) {
  ref.watch(workspaceRootProvider);
  return const FileFilter();
});

class _LinkTargetPicker extends ConsumerStatefulWidget {
  const _LinkTargetPicker({this.initial});

  /// 현재 값(대상 노드 id 문자열). 그 노드에 커서를 얹고 표식을 단다.
  final String? initial;

  @override
  ConsumerState<_LinkTargetPicker> createState() => _LinkTargetPickerState();
}

class _LinkTargetPickerState extends ConsumerState<_LinkTargetPicker>
    with CursorRevealMixin<_LinkTargetPicker> {
  final ScrollController _scroll = ScrollController();

  /// 목록이 **직접** 쥐어야 하는 포커스. 빠른 탐색은 이 노드가 primary일 때만 글자를
  /// 받으므로([typeAheadCharacter]), 필터 칸이 아니라 목록이 기본 포커스를 갖는다.
  final FocusNode _listFocus = FocusNode(debugLabel: 'linkTargetList');

  /// 커서가 놓인 후보의 노드 id. 걸러져 목록에서 사라지면 자리를 잃을 뿐 비우지는
  /// 않는다 — 필터를 되돌리면 보던 자리로 돌아온다.
  int? _cursorId;

  /// 이름 검색어(모바일 전용 칸이 채운다).
  String _query = '';

  /// 이번 build의 후보들. 키 처리가 목록 순서를 그대로 봐야 해서 들고 있는다.
  List<FileNode> _matches = const [];

  @override
  ScrollController get revealScrollController => _scroll;

  @override
  int get cursorRowIndex => _matches.indexWhere((n) => n.id == _cursorId);

  @override
  int get revealRowCount => _matches.length;

  @override
  void initState() {
    super.initState();
    // 지금 값이 있으면 그 자리에서 시작한다 — 무엇을 가리키고 있었는지 보이고,
    // 빠른 탐색도 거기서부터 훑는다.
    _cursorId = int.tryParse(widget.initial ?? '');
  }

  @override
  void dispose() {
    _scroll.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 대상은 파일과 키워드만 후보로 낸다 — 폴더는 이미지·링크 대상이 아니다. 키워드는
    // 링크로 가리키라고 만든 노드라 반드시 들어간다(작가 정보 등).
    final nodes = [
      for (final n in ref.watch(fileNodesProvider).valueOrNull ?? const [])
        if (!n.isDirectory && n.id != null) n,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 필터는 목록·그룹과 같은 규칙으로 건다 — 링크 값이 대상 이름으로 풀린 부여 맵을
    // 쓰므로, 도구모음에서 통하던 조건이 여기서도 그대로 통한다.
    final filter = ref.watch(_rememberedFilterProvider);
    final assignments = ref.watch(resolvedAssignmentsByFileProvider);
    final query = _query.trim().toLowerCase();
    _matches = [
      for (final n in nodes)
        if ((query.isEmpty || n.name.toLowerCase().contains(query)) &&
            (filter.isEmpty || filter.matches(assignments[n.id] ?? const [])))
          n,
    ];

    final initialId = int.tryParse(widget.initial ?? '');
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.linkTargetPickerTitle),
      content: dialogContentBox(
        context,
        width: 420,
        height: 480,
        child: Column(
          children: [
            // 조각 문법은 데스크톱에서만 낸다(도구모음의 조건 줄과 같은 이유 —
            // 캡슐을 되펼치는 조작이 백스페이스/Delete를 전제하고, 자동완성 목록이
            // 소프트 키보드와 자리를 다툰다). 모바일은 이름 검색으로 갈린다.
            isDesktopPlatform ? _filterField(l10n, filter) : _nameField(l10n),
            const SizedBox(height: 8),
            Expanded(child: _list(l10n, initialId)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  /// 후보 목록. 데스크톱에서는 이 자리가 포커스를 쥐고 방향키·글자·Enter를 받는다.
  Widget _list(AppLocalizations l10n, int? initialId) {
    return TypeAheadOverlay(
      child: Focus(
        focusNode: _listFocus,
        autofocus: isDesktopPlatform,
        onKeyEvent: _onKeyEvent,
        child: _matches.isEmpty
            ? Center(child: Text(l10n.linkTargetNoMatch))
            : ListView.builder(
                controller: _scroll,
                itemCount: _matches.length,
                itemBuilder: (context, i) => _tile(_matches[i], initialId),
              ),
      ),
    );
  }

  /// 태그 필터 입력. 캡슐 필드는 테두리가 없으므로 검색 칸과 같은 테두리·아이콘 안에
  /// 앉혀 여느 입력 칸처럼 보이게 한다. 포커스를 가져가지 않는다 — 목록이 쥐고 있어야
  /// 빠른 탐색이 글자를 받는다.
  ///
  /// 감싼 [Focus]는 **목록으로 돌아오는 길**이다. 자리를 스스로 차지하지 않고, 안쪽
  /// 입력이 처리하지 않고 흘려보낸 키만 받는다 — 자동완성 목록이 떠 있는 동안에는
  /// Enter·Esc가 그쪽 몫(고르기·닫기)이라 여기까지 오지 않는다.
  Widget _filterField(AppLocalizations l10n, FileFilter filter) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _onFilterKeyEvent,
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.filter_alt_outlined),
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        child: FilterQueryField(
          filter: filter,
          definitions: ref.watch(pickableTagDefinitionsProvider),
          hintText: l10n.linkTargetFilterHint,
          onChanged: (next) =>
              ref.read(_rememberedFilterProvider.notifier).state = next,
        ),
      ),
    );
  }

  /// 이름 검색만 받는 칸(모바일).
  Widget _nameField(AppLocalizations l10n) {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.linkTargetSearchHint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) => setState(() => _query = v),
    );
  }

  Widget _tile(FileNode node, int? initialId) {
    final cursored = node.id == _cursorId;
    final scheme = Theme.of(context).colorScheme;
    return EnsureVisibleOnFocus(
      active: cursored,
      request: cursorReveal,
      child: ListTile(
        selected: cursored,
        selectedTileColor: scheme.primaryContainer,
        leading: FileThumbnail(node: node, dimension: 40),
        title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(node.path, maxLines: 1, overflow: TextOverflow.ellipsis),
        // 지금 가리키고 있는 대상은 커서가 떠나도 알아볼 수 있어야 한다.
        trailing: node.id == initialId ? const Icon(Icons.check) : null,
        onTap: () => _pick(node),
      ),
    );
  }

  // ── 키 조작 ──

  /// 필터를 다 걸었으니 목록으로 — Enter(확정)와 Esc(그만)가 같은 곳으로 간다.
  /// 어느 쪽 손버릇이든 통해야 하고, 둘 다 "이 칸에서의 일이 끝났다"는 뜻이다.
  /// Esc를 여기서 삼키므로 다이얼로그를 닫으려면 목록에서 한 번 더 눌러야 하는데,
  /// 목록이 기본 자리라 평소에는 한 번으로 닫힌다.
  KeyEventResult _onFilterKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.escape:
        _listFocus.requestFocus();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final character = typeAheadCharacter(node, event);
    if (character != null) return _typeAhead(character);
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        return _step(1);
      case LogicalKeyboardKey.arrowUp:
        return _step(-1);
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        final index = cursorRowIndex;
        if (index < 0) return KeyEventResult.ignored;
        _pick(_matches[index]);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 글자를 이어 쳐 그 글자로 시작하는 후보로 커서를 옮긴다. 맞는 것이 없어도 글자는
  /// 삼킨다 — 검색어는 이미 늘어났고(표시가 그것을 보여준다), 흘려보내면 그 글자가
  /// 딴 데서 다른 뜻으로 쓰인다.
  KeyEventResult _typeAhead(String character) {
    final target = ref
        .read(typeAheadProvider.notifier)
        .type(
          character,
          names: [for (final n in _matches) n.name],
          current: cursorRowIndex,
        );
    if (target != null) _moveCursorTo(_matches[target].id);
    return KeyEventResult.handled;
  }

  KeyEventResult _step(int delta) {
    if (_matches.isEmpty) return KeyEventResult.ignored;
    _moveCursorTo(
      stepNodeCursor([for (final n in _matches) n.id!], _cursorId, delta),
    );
    return KeyEventResult.handled;
  }

  void _moveCursorTo(int? id) {
    if (id == null || id == _cursorId) return;
    setState(() => _cursorId = id);
    requestCursorReveal();
  }

  void _pick(FileNode node) => Navigator.of(context).pop(node.id!.toString());
}
