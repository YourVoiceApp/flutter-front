import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_job.dart';

/// 파일 선택 + 폴더 지정(새 폴더 추가 가능) → [VoiceJob] 반환
class VoiceUploadSheet extends StatefulWidget {
  const VoiceUploadSheet({
    super.key,
    required this.folders,
    required this.onCreateFolder,
    this.initialFolderId,
  });

  final List<VoiceFolder> folders;

  /// 폴더 화면에서 올릴 때 미리 선택
  final String? initialFolderId;
  /// 새 폴더 id 반환 (저장 후)
  final Future<String> Function(String name) onCreateFolder;

  @override
  State<VoiceUploadSheet> createState() => _VoiceUploadSheetState();
}

class _VoiceUploadSheetState extends State<VoiceUploadSheet> {
  String? _pickedName;
  late String _folderId;
  final _newFolderCtrl = TextEditingController();
  final _uuid = const Uuid();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _folderId = _initialOrDefault();
  }

  String _initialOrDefault() {
    final initial = widget.initialFolderId;
    if (initial != null &&
        widget.folders.any((f) => f.id == initial)) {
      return initial;
    }
    try {
      return widget.folders
          .firstWhere((f) => f.id == VoiceFolder.uncategorizedId)
          .id;
    } catch (_) {
      return widget.folders.isEmpty
          ? VoiceFolder.uncategorizedId
          : widget.folders.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant VoiceUploadSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.folders.any((f) => f.id == _folderId)) {
      _folderId = _fallbackFolderId();
    }
  }

  String _fallbackFolderId() {
    try {
      return widget.folders
          .firstWhere((f) => f.id == VoiceFolder.uncategorizedId)
          .id;
    } catch (_) {
      return widget.folders.isEmpty
          ? VoiceFolder.uncategorizedId
          : widget.folders.first.id;
    }
  }

  @override
  void dispose() {
    _newFolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (r == null || r.files.isEmpty) return;
    final name = r.files.single.name;
    if (name.isEmpty) return;
    setState(() => _pickedName = name);
  }

  Future<void> _submitNewFolder() async {
    final name = _newFolderCtrl.text;
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('폴더 이름을 입력해 주세요.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await widget.onCreateFolder(name);
      if (!mounted) return;
      _newFolderCtrl.clear();
      setState(() {
        _folderId = id;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  void _confirm() {
    if (_pickedName == null) return;
    final job = VoiceJob(
      id: 'job-${_uuid.v4()}',
      fileName: _pickedName!,
      status: VoiceJobStatus.uploaded,
      createdAt: DateTime.now(),
      folderId: _folderId,
      origin: VoiceOrigin.uploaded,
    );
    Navigator.of(context).pop<VoiceJob>(job);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final folders = List<VoiceFolder>.from(widget.folders)
      ..sort((a, b) {
        if (a.id == VoiceFolder.uncategorizedId) return -1;
        if (b.id == VoiceFolder.uncategorizedId) return 1;
        return a.name.compareTo(b.name);
      });

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottom + 16,
      ),
      child: SingleChildScrollView(
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
            const Text(
              '음성 올리기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '파일을 고르고 넣을 폴더를 정해요. 새 폴더도 여기서 만들 수 있어요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.audio_file_outlined),
              label: Text(_pickedName ?? '파일 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: YeolpumtaTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: YeolpumtaTheme.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '폴더',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: YeolpumtaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YeolpumtaTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: folders.any((f) => f.id == _folderId)
                      ? _folderId
                      : folders.first.id,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    for (final f in folders)
                      DropdownMenuItem(
                        value: f.id,
                        child: Text(
                          f.isUncategorized ? '${f.name} (기본)' : f.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _folderId = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newFolderCtrl,
                    decoration: InputDecoration(
                      hintText: '새 폴더 이름',
                      hintStyle: const TextStyle(
                        color: YeolpumtaTheme.textSecondary,
                      ),
                      filled: true,
                      fillColor: YeolpumtaTheme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: YeolpumtaTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: YeolpumtaTheme.divider),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submitNewFolder(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _busy ? null : _submitNewFolder,
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _pickedName == null ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: YeolpumtaTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '이 폴더에 올리기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
