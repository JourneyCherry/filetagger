import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableTextWidget extends StatefulWidget {
  final String initialText;
  final Function(String)? onSaved;
  final List<TextInputFormatter>? inputFormatter;

  const EditableTextWidget({
    super.key,
    required this.initialText,
    this.onSaved,
    this.inputFormatter,
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
    return GestureDetector(
      onTap: _startEditing,
      onDoubleTap: _startEditing,
      child: _isEditing
          ? SizedBox(
              width: 200,
              child: TextField(
                inputFormatters: widget.inputFormatter,
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _saveChanges(),
              ),
            )
          : Text(
              _controller.text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
