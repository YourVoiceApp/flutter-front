import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_upload_request.dart';
import 'read_recording_output.dart';

/// 마이크 녹음 + 폴더 선택 → [VoiceUploadRequest]
class VoiceRecordSheet extends StatefulWidget {
  const VoiceRecordSheet({
    super.key,
    required this.folders,
    required this.onCreateFolder,
    this.initialFolderId,
  });

  final List<VoiceFolder> folders;
  final String? initialFolderId;

  final Future<String> Function(String name, String? parentFolderId)
  onCreateFolder;

  @override
  State<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<VoiceRecordSheet> {
  late final AudioRecorder _recorder = AudioRecorder();

  late String _folderId;
  final _newFolderCtrl = TextEditingController();

  bool _busy = false;
  bool _isRecording = false;
  AudioEncoder? _encoderUsed;
  Uint8List? _recordedBytes;
  String? _recordedName;

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
  void didUpdateWidget(covariant VoiceRecordSheet oldWidget) {
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
    _recorder.dispose();
    super.dispose();
  }

  String _extensionForEncoder(AudioEncoder encoder) {
    switch (encoder) {
      case AudioEncoder.wav:
        return 'wav';
      case AudioEncoder.pcm16bits:
        return 'pcm';
      case AudioEncoder.aacLc:
      case AudioEncoder.aacEld:
      case AudioEncoder.aacHe:
        return 'm4a';
      case AudioEncoder.amrNb:
      case AudioEncoder.amrWb:
        return '3gp';
      case AudioEncoder.opus:
        return 'opus';
      case AudioEncoder.flac:
        return 'flac';
    }
  }

  Future<AudioEncoder> _pickEncoder() async {
    const order = <AudioEncoder>[
      AudioEncoder.wav,
      AudioEncoder.aacLc,
    ];
    for (final enc in order) {
      if (await _recorder.isEncoderSupported(enc)) {
        return enc;
      }
    }
    return AudioEncoder.aacLc;
  }

  Future<String> _outputPath(AudioEncoder encoder) async {
    final dir = await getTemporaryDirectory();
    final ext = _extensionForEncoder(encoder);
    return '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;

    if (!_isRecording) {
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요해요.')),
        );
        return;
      }

      setState(() => _busy = true);
      try {
        final encoder = await _pickEncoder();
        final path = await _outputPath(encoder);
        await _recorder.start(RecordConfig(encoder: encoder), path: path);
        if (!mounted) return;
        setState(() {
          _busy = false;
          _isRecording = true;
          _encoderUsed = encoder;
          _recordedBytes = null;
          _recordedName = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('녹음을 시작할 수 없어요: $e')));
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final out = await _recorder.stop();
      final raw = await readRecordingOutputBytes(out);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _isRecording = false;
      });

      if (raw == null || raw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음 데이터를 읽지 못했어요.')),
        );
        return;
      }

      final enc = _encoderUsed ?? await _pickEncoder();
      final ext = _extensionForEncoder(enc);
      final name =
          '녹음_${DateTime.now().toIso8601String().replaceAll(':', '-')}'
          '.$ext';

      setState(() {
        _recordedBytes = Uint8List.fromList(raw);
        _recordedName = name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _isRecording = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('녹음을 저장할 수 없어요: $e')));
    }
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
    final bytes = _recordedBytes;
    final name = _recordedName;
    if (bytes == null || name == null) return;

    final base = name.contains('.') ? name.split('.').first : name;
    final request = VoiceUploadRequest(
      filename: name,
      bytes: bytes,
      folderId: _folderId,
      name: base,
    );
    Navigator.of(context).pop<VoiceUploadRequest>(request);
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final folders = _orderedFolders();
    final recorded = _recordedBytes != null;

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
              '직접 녹음',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '녹음을 마친 뒤 넣을 폴더를 골라 올려요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: _busy ? null : _toggleRecording,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: _isRecording
                    ? Colors.red.shade50
                    : YeolpumtaTheme.accentSoft,
                foregroundColor: _isRecording
                    ? Colors.red.shade700
                    : YeolpumtaTheme.accent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _busy
                        ? '처리 중…'
                        : _isRecording
                        ? '녹음 중지'
                        : '녹음 시작',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (recorded && _recordedName != null) ...[
              const SizedBox(height: 12),
              Text(
                '저장됨 · ${_recordedName!}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: YeolpumtaTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
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
                  onChanged: _isRecording || _busy
                      ? null
                      : (v) {
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
                    enabled: !_isRecording && !_busy,
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
                  onPressed:
                      _busy || _isRecording ? null : _submitNewFolder,
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: recorded && !_busy ? _confirm : null,
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
