import 'package:flutter/material.dart';

class EditableTextWidget extends StatefulWidget {
  ///초기값. controller를 입력받으면 무시
  final String? initialText;
  final Function(String)? onSaved;
  final bool Function(String)? isValid;
  final String? defaultString;

  ///텍스트용 컨트롤러. 설정하면 initialText 필드를 무시하고 controller의 값을 초기값으로 사용
  final TextEditingController? controller;

  const EditableTextWidget({
    super.key,
    this.initialText,
    this.onSaved,
    this.isValid,
    this.defaultString,
    this.controller,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialText);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveChanges();
      }
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _saveChanges() {
    setState(() => _isEditing = false);
    widget.onSaved?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _startEditing,
          onDoubleTap: _startEditing,
          child: _isEditing
              ? SizedBox(
                  width: 200,
                  child: TextFormField(
                    style: Theme.of(context).textTheme.titleMedium,
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 1.0,
                      ),
                      errorStyle: TextStyle(
                        //TODO : TextFormField와 ErrorMessage 사이의 간격을 아래의 Text와 Padding의 간격만큼 줄이기
                        color: Colors.red,
                        fontSize: 8,
                      ),
                    ),
                    onFieldSubmitted: (_) => _saveChanges(),
                    validator: (value) {
                      if (value == null) return null;
                      if (widget.isValid == null) return null;
                      if (widget.isValid!(value)) return null;
                      return 'it will be set as \'${widget.defaultString}\'';
                    },
                    autovalidateMode: AutovalidateMode.always,
                  ),
                )
              : Text(
                  _controller.text,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                ),
        ),
        if (!_isEditing &&
            widget.isValid != null &&
            !widget.isValid!(_controller.text))
          Padding(
            padding: EdgeInsets.only(top: 0),
            child: Text(
              'it will be set as \'${widget.defaultString}\'',
              style: TextStyle(
                color: Colors.red,
                fontSize: 8,
              ),
            ),
          )
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) {
      //widget.controller가 null이면 자체 생산 컨트롤러임.
      //controller의 소멸 책임은 생성한 위젯에 있으므로, 주입된 controller는 소멸시키지 않음
      _controller.dispose();
    }
    super.dispose();
  }
}
