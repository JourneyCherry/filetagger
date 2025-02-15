import 'package:flutter/material.dart';

class RichString {
  final String text;
  final bool bold;

  const RichString(this.text, {this.bold = false});
}

class TagIconWidget extends StatelessWidget {
  static const double height = 20;
  static const double minWidth = 20;
  static const double maxWidth = 150;

  const TagIconWidget({
    super.key,
    this.textColor,
    this.backgroundColor = Colors.lightBlue,
    this.texts,
    this.onPressed,
  });

  final List<RichString>? texts;
  final Color? textColor;
  final Color backgroundColor; //Background Color
  final void Function()? onPressed;

  /// 배경색에 따라 식별하기 좋은 색을 만드는 함수.
  /// 글자색에 사용
  Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> spannedTexts = [];
    final Color txtColor = textColor ?? getTextColor(backgroundColor);
    texts?.forEach(
      (element) => spannedTexts.add(
        TextSpan(
          text: element.text,
          style: TextStyle(
            color: txtColor,
            fontWeight: element.bold ? FontWeight.bold : null,
          ),
        ),
      ),
    );
    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size(minWidth, height),
            maximumSize: Size(maxWidth, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: backgroundColor,
          ),
          child: SizedBox(
            width: double.infinity,
            child: RichText(
              text: TextSpan(
                children: spannedTexts,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(1.0),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
