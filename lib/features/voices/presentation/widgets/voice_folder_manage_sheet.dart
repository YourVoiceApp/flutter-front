import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';

/// 폴더 추가 · 이름 바꾸기 · 삭제 (미분류만 삭제 불가)
class VoiceFolderManageSheet extends StatefulWidget {
  const VoiceFolderManageSheet({
    super.key,
    required this.folders,
    this.currentFolderId,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<VoiceFolder> folders;
  final String? currentFolderId;
  final Future<void> Function(String name, String? parentFolderId) onCreate;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('폴더 이름을 입력해 주세요.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCreate(name, _createParentFolderId());
      if (!mounted) return;
      _newCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
        content: Text('「${f.name}」 안의 음성은 미분류로 옮겨요. 계속할까요?'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sorted = _orderedFolders();
    final currentParentLabel = _currentParentLabel();

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
            if (currentParentLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YeolpumtaTheme.divider),
                ),
                child: Text(
                  '생성 위치: $currentParentLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                        borderSide: const BorderSide(
                          color: YeolpumtaTheme.divider,
                        ),
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
                  title: Padding(
                    padding: EdgeInsets.only(left: _folderDepth(f.id) * 14.0),
                    child: Text(
                      f.isUncategorized ? '${f.name} (삭제 불가)' : f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  subtitle: Text(
                    _subtitleForFolder(f),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '이름 바꾸기',
                        onPressed: _busy || f.isUncategorized
                            ? null
                            : () => _rename(f),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: YeolpumtaTheme.textSecondary,
                      ),
                      if (canDelete)
                        IconButton(
                          tooltip: '삭제',
                          onPressed: _busy || _hasChildren(f.id)
                              ? null
                              : () => _confirmDelete(f),
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

  String? _createParentFolderId() {
    final currentFolderId = widget.currentFolderId;
    if (currentFolderId == null ||
        currentFolderId == VoiceFolder.uncategorizedId) {
      return null;
    }
    return currentFolderId;
  }

  String? _currentParentLabel() {
    final parentId = _createParentFolderId();
    if (parentId == null) return null;
    return _folderPath(parentId);
  }

  List<VoiceFolder> _orderedFolders() {
    final byParent = <String?, List<VoiceFolder>>{};
    for (final folder in widget.folders) {
      byParent.putIfAbsent(folder.parentId, () => <VoiceFolder>[]).add(folder);
    }
    for (final folders in byParent.values) {
      folders.sort((a, b) {
        if (a.id == VoiceFolder.uncategorizedId) return -1;
        if (b.id == VoiceFolder.uncategorizedId) return 1;
        return a.name.compareTo(b.name);
      });
    }

    final ordered = <VoiceFolder>[];
    final visited = <String>{};

    void visit(String? parentId) {
      for (final folder in byParent[parentId] ?? const <VoiceFolder>[]) {
        if (!visited.add(folder.id)) continue;
        ordered.add(folder);
        visit(folder.id);
      }
    }

    visit(null);
    for (final folder in widget.folders) {
      if (visited.add(folder.id)) {
        ordered.add(folder);
      }
    }
    return ordered;
  }

  bool _hasChildren(String folderId) {
    return widget.folders.any((f) => f.parentId == folderId);
  }

  int _folderDepth(String folderId) {
    var depth = 0;
    final seen = <String>{folderId};
    var current = _folderById(folderId);
    while (current?.parentId != null) {
      final parentId = current!.parentId!;
      if (!seen.add(parentId)) break;
      current = _folderById(parentId);
      if (current == null) break;
      depth++;
    }
    return depth;
  }

  String _subtitleForFolder(VoiceFolder folder) {
    if (folder.isUncategorized) return '기본 폴더';
    final childCount = widget.folders
        .where((f) => f.parentId == folder.id)
        .length;
    if (childCount > 0) {
      return '하위 폴더 $childCount개 · 만든 날: ${_fmt(folder.createdAt)}';
    }
    return '만든 날: ${_fmt(folder.createdAt)}';
  }

  String _folderPath(String folderId) {
    final parts = <String>[];
    final seen = <String>{};
    var currentId = folderId;
    while (seen.add(currentId)) {
      VoiceFolder? folder;
      for (final item in widget.folders) {
        if (item.id == currentId) {
          folder = item;
          break;
        }
      }
      if (folder == null) break;
      parts.add(folder.name);
      final parentId = folder.parentId;
      if (parentId == null) break;
      currentId = parentId;
    }
    return parts.reversed.join(' / ');
  }

  VoiceFolder? _folderById(String id) {
    for (final folder in widget.folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
