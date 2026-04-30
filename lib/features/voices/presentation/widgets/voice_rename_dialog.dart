import 'package:flutter/material.dart';

/// 취소·배경 탭 등으로 닫히면 `null`, 저장하면 공백 제거 후 문자열(빈 문자열 포함).
Future<String?> showVoiceRenameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _VoiceRenameDialogBody(initialName: initialName),
  );
}

class _VoiceRenameDialogBody extends StatefulWidget {
  const _VoiceRenameDialogBody({required this.initialName});

  final String initialName;

  @override
  State<_VoiceRenameDialogBody> createState() => _VoiceRenameDialogBodyState();
}

class _VoiceRenameDialogBodyState extends State<_VoiceRenameDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('음성 이름'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '새 이름'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
