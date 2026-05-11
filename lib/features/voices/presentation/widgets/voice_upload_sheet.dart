import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_upload_request.dart';
import 'voice_record_sheet.dart';
import 'wav_duration_trim.dart';

/// 파일 선택 + 폴더 지정(새 폴더 추가 가능) → [VoiceUploadRequest] 반환
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
  final Future<String> Function(String name, String? parentFolderId)
  onCreateFolder;

  @override
  State<VoiceUploadSheet> createState() => _VoiceUploadSheetState();
}

class _VoiceUploadSheetState extends State<VoiceUploadSheet> {
  PlatformFile? _pickedFile;
  Uint8List? _pickedBytesForUpload;
  double? _pickedDurationSec;
  bool _trimmedFromStart = false;
  late String _folderId;
  final _newFolderCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _folderId = _initialOrDefault();
  }

  String _initialOrDefault() {
    final initial = widget.initialFolderId;
    if (initial != null && widget.folders.any((f) => f.id == initial)) {
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
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3'],
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    final file = r.files.single;
    if (file.name.isEmpty || file.bytes == null) return;
    final lower = file.name.toLowerCase();
    if (!lower.endsWith('.wav')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자동 길이 보정은 WAV만 지원해요. wav 파일로 올려 주세요.'),
        ),
      );
      return;
    }

    final trimmed = WavDurationTrim.trimToMaxKeepingTail(
      wavBytes: file.bytes!,
      minSeconds: VoiceRecordLimits.minSeconds,
      maxSeconds: VoiceRecordLimits.maxSeconds,
    );
    if (trimmed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WAV 파일 분석에 실패했어요. 다른 파일로 다시 시도해 주세요.'),
        ),
      );
      return;
    }
    if (trimmed.durationSeconds < VoiceRecordLimits.minSeconds) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '업로드는 ${VoiceRecordLimits.minSeconds}~${VoiceRecordLimits.maxSeconds}초만 가능해요. '
            '(현재 ${trimmed.durationSeconds.toStringAsFixed(1)}초)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _pickedBytesForUpload = trimmed.bytes;
      _pickedDurationSec = trimmed.durationSeconds;
      _trimmedFromStart = trimmed.trimmedFromStart;
    });
  }

  Future<void> _submitNewFolder() async {
    final name = _newFolderCtrl.text;
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('폴더 이름을 입력해 주세요.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await widget.onCreateFolder(name, _newFolderParentId());
      if (!mounted) return;
      _newFolderCtrl.clear();
      setState(() {
        _folderId = id;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _confirm() {
    final pickedFile = _pickedFile;
    final uploadBytes = _pickedBytesForUpload;
    if (pickedFile == null || uploadBytes == null) return;
    final request = VoiceUploadRequest(
      filename: pickedFile.name,
      bytes: uploadBytes,
      folderId: _folderId,
      name: pickedFile.name.split('.').first,
    );
    Navigator.of(context).pop<VoiceUploadRequest>(request);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final folders = _orderedFolders();

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
              label: Text(_pickedFile?.name ?? '파일 선택 (.wav / .mp3)'),
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
            if (_pickedFile != null && _pickedDurationSec != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: YeolpumtaTheme.divider),
                ),
                child: Text(
                  _trimmedFromStart
                      ? '길이 ${_pickedDurationSec!.toStringAsFixed(1)}초 · 앞부분을 잘라 최근 ${VoiceRecordLimits.maxSeconds}초로 맞췄어요.'
                      : '길이 ${_pickedDurationSec!.toStringAsFixed(1)}초 · 업로드 가능 길이예요.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                          _folderDropdownLabel(f),
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
                        borderSide: const BorderSide(
                          color: YeolpumtaTheme.divider,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: YeolpumtaTheme.divider,
                        ),
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
              onPressed: _pickedFile == null ? null : _confirm,
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

  String? _newFolderParentId() {
    if (_folderId == VoiceFolder.uncategorizedId) return null;
    return _folderId;
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

  String _folderDropdownLabel(VoiceFolder folder) {
    final prefix = folder.isUncategorized ? '${folder.name} (기본)' : folder.name;
    final path = _folderPath(folder.id);
    if (path == folder.name || folder.isUncategorized) return prefix;
    return path;
  }

  String _folderPath(String folderId) {
    final parts = <String>[];
    final seen = <String>{};
    var currentId = folderId;
    while (seen.add(currentId)) {
      VoiceFolder? current;
      for (final folder in widget.folders) {
        if (folder.id == currentId) {
          current = folder;
          break;
        }
      }
      if (current == null) break;
      parts.add(current.name);
      final parentId = current.parentId;
      if (parentId == null) break;
      currentId = parentId;
    }
    return parts.reversed.join(' / ');
  }
}
