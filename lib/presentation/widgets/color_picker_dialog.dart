/// 팔레트에 없는 색을 직접 고르는 다이얼로그.
///
/// 채도·명도 판과 색상 띠로 대충 잡고 R·G·B 칸으로 정확히 맞춘다 — 두 입력이 같은 색
/// 하나를 양방향으로 가리킨다. 색상 선택을 제공하는 공식 패키지가 없어 직접 짠다
/// (근거는 ARCHITECTURE.md의 의존성 메모).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../tag_visuals.dart';
import 'dialog_utils.dart';

/// 다이얼로그 본문의 폭(원하는 값 — 좁은 화면에선 깎인다).
const double _dialogWidth = 320;

/// 채도·명도를 고르는 사각 판의 높이.
const double _areaHeight = 176;

/// 색상 띠의 높이.
const double _hueBarHeight = 24;

/// 판·띠 위에 놓아 고른 자리를 가리키는 표식의 지름과 테두리 두께.
const double _thumbSize = 18;
const double _thumbBorderWidth = 2;

/// 고른 색을 넓은 면으로 보여 주는 미리보기의 한 변.
const double _previewSize = 48;

/// 판·띠·미리보기의 모서리 둥글기.
const double _cornerRadius = 8;

/// 색상환 한 바퀴. HSV의 색상값이 도는 범위이자 띠의 좌우 끝이다.
const double _hueTurn = 360;

/// 색상 띠 그라데이션의 정지점 간격. 좁을수록 띠가 색상환에 가까워진다.
const double _hueStopStep = 60;

/// 한 채널이 담는 가장 큰 값. 칸이 받을 범위이자 채널을 꺼낼 때 쓰는 마스크다.
const int _channelMax = 0xFF;

/// ARGB 정수에서 각 채널이 앉은 자리.
const int _redShift = 16;
const int _greenShift = 8;
const int _blueShift = 0;

/// 색상 띠의 그라데이션 정지점. 색상값에서 그대로 만들어 색 상수를 손으로 적지 않는다.
final List<Color> _hueStops = [
  for (double h = 0; h <= _hueTurn; h += _hueStopStep)
    HSVColor.fromAHSV(1, h % _hueTurn, 1, 1).toColor(),
];

/// 색을 하나 고르게 하고 저장 형식(불투명 ARGB 정수)으로 돌려준다. 취소하면 null.
///
/// '색 없음'은 여기서 고르지 않는다 — 팔레트 그리드가 이미 그 자리를 갖고 있어,
/// 이 다이얼로그는 색을 하나 정하는 일만 한다.
Future<int?> showColorPickerDialog(BuildContext context, {int? initialColor}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _ColorPickerDialog(initialColor: initialColor),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.initialColor});

  /// 열 때 잡아 둘 색. 없으면 팔레트의 첫 색에서 시작한다(시작색을 여기서 새로
  /// 만들지 않는다).
  final int? initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  /// 고른 색의 단일 출처. R·G·B 칸은 이것을 비추기만 한다.
  ///
  /// ARGB 정수가 아니라 HSV로 들고 있는 이유는 **정수로 표현되지 않는 상태**가 있기
  /// 때문이다 — 검정·회색은 색상값이 어디를 가리키든 같은 정수라, 정수를 오갔다면
  /// 명도를 내렸다 올리는 사이 색상이 처음으로 돌아간다.
  late HSVColor _hsv = HSVColor.fromColor(
    Color(widget.initialColor ?? tagColorPalette.first),
  ).withAlpha(1);

  late final Map<int, TextEditingController> _channels = {
    for (final shift in _channelShifts)
      shift: TextEditingController(text: '${_channelOf(_argb, shift)}'),
  };

  int get _argb => _hsv.toColor().toARGB32();

  @override
  void dispose() {
    for (final controller in _channels.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 판·띠에서 고른 색을 반영하고 R·G·B 칸을 따라 맞춘다.
  void _setHsv(HSVColor next) {
    setState(() => _hsv = next);
    for (final entry in _channels.entries) {
      final text = '${_channelOf(_argb, entry.key)}';
      if (entry.value.text != text) entry.value.text = text;
    }
  }

  /// R·G·B 칸에 친 숫자를 색으로 반영한다. 칸의 글자는 건드리지 않는다 — 치는 도중에
  /// 정규화하면 커서가 튄다. 비운 칸은 바닥값으로 읽어, 지우고 다시 치는 동안에도
  /// 색이 따라온다.
  void _onChannelsChanged() {
    var argb = opaqueTagColorBits;
    for (final entry in _channels.entries) {
      argb |= (int.tryParse(entry.value.text) ?? 0) << entry.key;
    }
    var next = HSVColor.fromColor(Color(argb)).withAlpha(1);
    // 무채색은 색상값이 정해지지 않아 바닥으로 떨어진다. 띠에서 잡아 둔 자리를 잃지
    // 않도록 지금 색상을 이어 쓴다.
    if (next.saturation == 0) next = next.withHue(_hsv.hue);
    setState(() => _hsv = next);
  }

  void _submit() => Navigator.of(context).pop(_argb);

  @override
  Widget build(BuildContext context) {
    final color = Color(_argb);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.colorPickerTitle),
      content: dialogContentBox(
        context,
        width: _dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _areaHeight,
              child: _SaturationValueArea(hsv: _hsv, onChanged: _setHsv),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _hueBarHeight,
              child: _HueBar(
                hue: _hsv.hue,
                onChanged: (hue) => _setHsv(_hsv.withHue(hue)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Preview(color: color),
                for (final shift in _channelShifts) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChannelField(
                      label: _channelLabels[shift]!,
                      controller: _channels[shift]!,
                      onChanged: (_) => _onChannelsChanged(),
                      onSubmitted: _submit,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonOk)),
      ],
    );
  }
}

/// 칸이 놓이는 순서(빨강·초록·파랑)와 각 칸의 이름.
const List<int> _channelShifts = [_redShift, _greenShift, _blueShift];
const Map<int, String> _channelLabels = {
  _redShift: 'R',
  _greenShift: 'G',
  _blueShift: 'B',
};

/// ARGB 정수에서 한 채널을 꺼낸다.
int _channelOf(int argb, int shift) => (argb >> shift) & _channelMax;

/// R·G·B 한 칸. 숫자만, 그것도 채널이 담을 수 있는 범위까지만 받는다.
class _ChannelField extends StatelessWidget {
  const _ChannelField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const _ChannelRangeFormatter(),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

/// 채널이 담을 수 있는 범위를 넘는 입력을 **거부**한다.
///
/// 넘는 값을 잘라 고쳐 쓰지 않는 이유는, 고쳐 쓰면 커서가 튀고 칸에 보이는 숫자와
/// 실제 색이 잠깐 어긋나기 때문이다. 거부하면 칸에는 늘 색과 같은 숫자만 남는다.
class _ChannelRangeFormatter extends TextInputFormatter {
  const _ChannelRangeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value > _channelMax) return oldValue;
    return newValue;
  }
}

/// 고른 색을 넓게 보여 주는 자리. 그 색 위에 얹힐 글자색([foregroundOn])으로 표식을
/// 그려, 칩이 되었을 때 읽히는지가 고르는 동안 함께 보인다.
class _Preview extends StatelessWidget {
  const _Preview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _previewSize,
      height: _previewSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Icon(Icons.sell, color: foregroundOn(color)),
    );
  }
}

/// 가로로 채도, 세로로 명도를 고르는 판. 바탕은 지금 색상의 가장 진한 색이고, 그 위에
/// 흰색·검정 그라데이션을 겹쳐 두 축을 만든다.
class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void pick(Offset local) {
          final saturation = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
          final value = 1 - (local.dy / constraints.maxHeight).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          onPanDown: (details) => pick(details.localPosition),
          onPanUpdate: (details) => pick(details.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                  ),
                ),
                // 흐린 쪽 끝을 투명한 '흰색'으로 두어야 중간이 회색으로 뜨지 않는다.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(
                    hsv.saturation * 2 - 1,
                    1 - hsv.value * 2,
                  ),
                  child: _Thumb(color: hsv.toColor()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 색상환을 가로로 펼친 띠.
class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void pick(Offset local) {
          final ratio = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onChanged(ratio * _hueTurn);
        }

        return GestureDetector(
          onPanDown: (details) => pick(details.localPosition),
          onPanUpdate: (details) => pick(details.localPosition),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_cornerRadius),
              gradient: LinearGradient(colors: _hueStops),
            ),
            child: Align(
              alignment: Alignment(hue / _hueTurn * 2 - 1, 0),
              child: _Thumb(color: HSVColor.fromAHSV(1, hue, 1, 1).toColor()),
            ),
          ),
        );
      },
    );
  }
}

/// 고른 자리를 가리키는 표식. 테두리를 그 색의 대비색으로 둘러 어떤 색 위에서도
/// 표식이 사라지지 않는다.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: foregroundOn(color),
          width: _thumbBorderWidth,
        ),
      ),
    );
  }
}
