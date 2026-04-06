import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';

/// 폴더 추가 · 이름 바꾸기 · 삭제 (미분류만 삭제 불가)
class VoiceFolderManageSheet extends StatefulWidget {
  const VoiceFolderManageSheet({
    super.key,
    required this.folders,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<VoiceFolder> folders;
  final Future<void> Function(String name) onCreate;
  final Future<void> Function(String id, String newName) onRename;
  final Future<void> Function(String id) onDelete;

  @override
  State<VoiceFolderManageSheet> createState() => _VoiceFolderManageSheetState();
}

class _VoiceFolderManageSheetState extends State<VoiceFolderManageSheet> {
  final _newCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _newCtrl.text;
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('폴더 이름을 입력해 주세요.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCreate(name);
      if (!mounted) return;
      _newCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(VoiceFolder f) async {
    final ctrl = TextEditingController(text: f.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 이름'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !mounted) return;
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onRename(f.id, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(VoiceFolder f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text(
          '「${f.name}」 안의 음성은 미분류로 옮겨요. 계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDelete(f.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sorted = List<VoiceFolder>.from(widget.folders)
      ..sort((a, b) {
        if (a.id == VoiceFolder.uncategorizedId) return -1;
        if (b.id == VoiceFolder.uncategorizedId) return 1;
        return a.name.compareTo(b.name);
      });

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: YeolpumtaTheme.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '폴더 관리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCtrl,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    hintText: '새 폴더 (예: 동물)',
                    filled: true,
                    fillColor: YeolpumtaTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: YeolpumtaTheme.divider),
                    ),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _busy ? null : _add,
                child: const Text('만들기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.expand((f) {
            final canDelete = !f.isUncategorized;
            return [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  f.isUncategorized ? '${f.name} (삭제 불가)' : f.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  f.isUncategorized ? '기본 폴더' : '만든 날: ${_fmt(f.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '이름 바꾸기',
                      onPressed: _busy ? null : () => _rename(f),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: YeolpumtaTheme.textSecondary,
                    ),
                    if (canDelete)
                      IconButton(
                        tooltip: '삭제',
                        onPressed: _busy ? null : () => _confirmDelete(f),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.redAccent,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ];
          }),
        ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
