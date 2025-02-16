import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableTextWidget extends StatefulWidget {
  final String initialText;
  final Function(String)? onSaved;
  final List<TextInputFormatter>? inputFormatter;
  final bool Function(String)? isValid;
  final String? defaultString;

  const EditableTextWidget({
    super.key,
    required this.initialText,
    this.onSaved,
    this.inputFormatter,
    this.isValid,
    this.defaultString,
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
    _controller = TextEditingController(text: widget.initialText);

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
                    inputFormatters: widget.inputFormatter,
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
    _controller.dispose();
    super.dispose();
  }
}
