import 'package:flutter/material.dart';

import '../tag_visuals.dart';

/// 모든 태그 캡슐이 공유하는 알약 모양 위젯. 부여 태그·필터 조건·정렬 단계, 그리고
/// 텍스트 입력 안에 접힌 캡슐까지 겉모습을 한 곳으로 모은다.
///
/// 양 끝이 둥근 한 모양으로 통일한다. 왼쪽 둥근 부위의 드래그 손잡이와 오른쪽 둥근
/// 부위의 제거(x) 버튼이 놓일 자리는 **늘 같은 너비로 비워 둔다** — 그 기능을 못 쓰는
/// 캡슐(예: 텍스트 입력 안의 캡슐, 표시 전용 태그)은 아이콘만 감추고 모양과 글자 위치는
/// 그대로 둔다. 손잡이는 [dragIndex]가, x는 [onDelete]가 주어질 때만 아이콘이 나타나고
/// 눌린다.
///
/// 배경색과 겹쳐도 읽히도록 글자색과 같은 얇은 테두리를 두르고, 이름과 값(필터·정렬은
/// 조건)은 문자가 아니라 같은 색 얇은 구분선으로 가른다 — 구분선은 위아래 테두리에
/// 닿아 캡슐을 두 칸으로 나눈다([value]가 없으면 구분선도 없다). 이름·값이 너무 길면
/// 뒤를 잘라 말줄임표로 보인다. 누를 수 있는 캡슐은 포인터가 올라오면 배경색 자체를
/// 갈아 끼워(잉크 오버레이가 아니라) 잉크 효과를 끈 데스크톱에서도 수정 가능함이 보인다.
class TagCapsule extends StatefulWidget {
  const TagCapsule({
    super.key,
    required this.background,
    required this.foreground,
    required this.name,
    this.namePrefix,
    this.value,
    this.onTap,
    this.dragIndex,
    this.onDelete,
    this.margin = EdgeInsets.zero,
  });

  final Color background;

  /// 글자색이자 테두리·구분선·아이콘의 색. 배경 대비 접근성 기준으로 고른 색을 넘긴다.
  final Color foreground;

  /// 태그 이름(구분선 왼쪽 본문).
  final String name;

  /// 이름 바로 앞에 놓는 조각(예: 제외 조건의 금지 아이콘).
  final Widget? namePrefix;

  /// 구분선 오른쪽에 놓는 값/조건. null이면 구분선도 값도 그리지 않는다.
  final Widget? value;

  /// 지정하면 캡슐을 눌러 편집할 수 있고, 포인터가 올라오면 배경이 바뀐다.
  final VoidCallback? onTap;

  /// 순서 변경 드래그를 받을 리스트 인덱스. null이면 손잡이 아이콘을 감춘다(자리는 유지).
  final int? dragIndex;

  /// 누르면 즉시 제거. null이면 x 아이콘을 감춘다(자리는 유지).
  final VoidCallback? onDelete;

  final EdgeInsetsGeometry margin;

  @override
  State<TagCapsule> createState() => _TagCapsuleState();
}

// 알약 겉모습을 이루는 치수의 단일 출처(주석엔 값 대신 역할만 둔다 — 컨벤션 2).
const double _borderWidth = 1; // 테두리·구분선 굵기.
// 캡슐 안 모든 아이콘(손잡이·x·제외·정렬 방향)의 공통 크기 — 단일 출처. 작을수록
// 아이콘을 담는 둥근 끝(_capWidth)을 좁힐 수 있어 이름·값이 더 앞으로 당겨진다.
const double kCapsuleIconSize = 12;
const double _deleteRadius = 14;
// 손잡이/x가 놓이는 둥근 끝의 고정 너비. 아이콘이 둥근 끝 안에 딱 담길 만큼만 두어
// (그 밖은 이름·값이 채우도록) 공백을 줄이되, 아이콘 유무와 무관하게 늘 같은 너비라
// 캡슐 폭이 흔들리지 않는다(칩↔텍스트 전환에서도 튀지 않는다). 아이콘 크기에 맞춰
// 정한 값이라 kCapsuleIconSize를 바꾸면 함께 조정한다.
const double _capWidth = 16;
const double _maxLabelWidth = 160; // 이름·값 한 칸의 최대 너비(넘으면 말줄임).
const double _fontSize = 13; // 캡슐 글자 크기(주변 텍스트 테마와 무관하게 고정).
const double _lineHeight = 1.2; // 캡슐 글자의 줄 높이 배수.
// 캡슐 높이를 하나로 못박아, 놓이는 자리(가로 목록이 세로로 늘리는 도구모음 등)와
// 무관하게 늘 같은 두께가 되게 한다. 태그 추가 버튼도 이 높이를 함께 쓴다.
const double _capsuleHeight = 23;
// 구분선 좌우(이름·값이 구분선에 붙지 않게)와 + 버튼 아이콘의 여백.
const double _dividerGap = 3;
// 둥근 끝(아이콘 자리) 쪽 — 이름 맨 앞·값 맨 뒤의 여백. 구분선 쪽보다 좁게 두어 이름·
// 값을 캡슐 양 끝으로 당긴다(손잡이/x가 없을 때 양옆이 휑해 보이지 않도록). 0이면
// 둥근 끝의 안쪽 경계에 딱 붙는다 — 음수는 Padding이 허용하지 않아 이것이 하한이다.
const double _endGap = 0;

class _TagCapsuleState extends State<TagCapsule> {
  bool _hovered = false;

  bool get _interactive => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final fg = widget.foreground;
    final bg = _interactive && _hovered
        ? hoverOn(widget.background)
        : widget.background;
    // 글자 크기·줄 높이를 고정해 어느 자리에 놓이든(주변 텍스트 테마·필드 편집
    // 스타일과 무관하게) 모든 캡슐의 높이·글자폭이 같아지게 한다.
    final style = const TextStyle().copyWith(
      color: fg,
      fontSize: _fontSize,
      height: _lineHeight,
    );

    final children = <Widget>[
      _handle(fg),
      _center(
        Padding(
          // 이름 맨 앞은 둥근 끝 쪽(좁게), 오른쪽은 값이 있으면 구분선 쪽(넓게),
          // 없으면 다시 둥근 끝 쪽.
          padding: EdgeInsets.only(
            left: _endGap,
            right: widget.value != null ? _dividerGap : _endGap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.namePrefix != null) ...[
                widget.namePrefix!,
                const SizedBox(width: 2),
              ],
              _clamped(
                Text(
                  widget.name,
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      if (widget.value != null) ...[
        _divider(fg),
        _center(
          Padding(
            // 값 맨 왼쪽은 구분선 쪽(넓게), 맨 오른쪽은 둥근 끝 쪽(좁게).
            padding: const EdgeInsets.only(left: _dividerGap, right: _endGap),
            child: _clamped(
              IconTheme.merge(
                data: IconThemeData(color: fg, size: kCapsuleIconSize),
                // 값이 글자면 이름과 같은 규칙으로 잘라 말줄임한다(아이콘은 그대로).
                child: DefaultTextStyle.merge(
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  child: widget.value!,
                ),
              ),
            ),
          ),
        ),
      ],
      _delete(fg),
    ];

    final shape = StadiumBorder(
      side: BorderSide(color: fg, width: _borderWidth),
    );
    final content = SizedBox(
      height: _capsuleHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    Widget capsule = Material(
      color: bg,
      shape: shape,
      child: _interactive
          ? InkWell(onTap: widget.onTap, customBorder: shape, child: content)
          : content,
    );
    if (_interactive) {
      capsule = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: capsule,
      );
    }
    return Padding(padding: widget.margin, child: capsule);
  }

  /// 세로로 늘어난 줄 칸 안에서 아이콘·글자를 가운데로, 너비는 내용만큼만.
  Widget _center(Widget child) => Center(widthFactor: 1, child: child);

  /// 한 칸의 최대 너비를 묶어 넘치는 이름·값이 말줄임되게 한다.
  Widget _clamped(Widget child) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
    child: child,
  );

  /// 아이콘 유무와 무관하게 늘 같은 너비를 차지하는 둥근 끝 자리. 채워지는 위젯은
  /// 이 칸(너비·높이 전체)을 채워 클릭·드래그 범위를 넓히고, 아이콘은 그 안에서
  /// 가운데로 둔다 — 아이콘을 작게 줄여도 누르기 쉬운 크기가 유지된다.
  Widget _cap(Widget? child) => SizedBox(width: _capWidth, child: child);

  Widget _handle(Color color) {
    if (widget.dragIndex == null) return _cap(null);
    return _cap(
      ReorderableDragStartListener(
        index: widget.dragIndex!,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              size: kCapsuleIconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _delete(Color color) {
    if (widget.onDelete == null) return _cap(null);
    return _cap(
      InkResponse(
        onTap: widget.onDelete,
        radius: _deleteRadius,
        child: Center(
          child: Icon(Icons.cancel, size: kCapsuleIconSize, color: color),
        ),
      ),
    );
  }

  Widget _divider(Color color) => Container(width: _borderWidth, color: color);
}

/// 태그 캡슐과 같은 알약 모양·높이·테두리를 가진 아이콘 버튼(태그 추가 '+' 등).
///
/// 목록·프리뷰에서 캡슐 옆에 놓여도 두께·모양이 어긋나지 않게, 캡슐과 같은 높이와
/// 테두리를 쓴다. 색은 어떤 태그도 가리키지 않는 중립 캡슐과 같은 톤으로 둔다.
class CapsuleAddButton extends StatelessWidget {
  const CapsuleAddButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSecondaryContainer;
    final shape = StadiumBorder(
      side: BorderSide(color: fg, width: _borderWidth),
    );

    Widget button = Material(
      color: scheme.secondaryContainer,
      shape: shape,
      child: InkWell(
        onTap: onPressed,
        customBorder: shape,
        child: SizedBox(
          height: _capsuleHeight,
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _dividerGap),
              child: Icon(icon, size: kCapsuleIconSize, color: fg),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
