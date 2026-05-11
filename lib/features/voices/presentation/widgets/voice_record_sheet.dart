import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_upload_request.dart';
import 'read_recording_output.dart';
import 'wav_duration_trim.dart';

/// 서버: 짧으면 거절(‘few seconds’), 파일 최대 약 [maxWaveBytesApprox] 근처 WAV.
/// WAV 44100 Hz 모노 16bit ≈ 88.2KB/s → 대략 32초까지가 3MB에 여유 있음.
abstract final class VoiceRecordLimits {
  static const int minSeconds = 5;
  static const int maxSeconds = 10;
  /// 최대 허용 시간에 맞춰 녹음을 자동 종료함.
  static const int autoStopAdvanceSeconds = 0;
}

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
  /// 마지막으로 완료된 녹음 길이(초)
  double? _recordedDurationSec;

  Stopwatch? _recordingStopwatch;
  Timer? _recordingTicker;
  bool _finishingRecording = false;

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

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _newFolderCtrl.dispose();
    _recorder.dispose();
    super.dispose();
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

  /// Backend [POST /voices/cloned-voice] accepts `.wav` / `.mp3` only.
  Future<AudioEncoder> _pickEncoder() async {
    if (await _recorder.isEncoderSupported(AudioEncoder.wav)) {
      return AudioEncoder.wav;
    }
    throw StateError(
      '이 기기에서 WAV 녹음을 지원하지 않아요. 파일 업로드로 mp3 또는 wav를 올려 주세요.',
    );
  }

  Future<String> _outputPath(AudioEncoder encoder) async {
    final dir = await getTemporaryDirectory();
    final ext = _extensionForEncoder(encoder);
    return '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  double _elapsedRecordingSec() {
    final sw = _recordingStopwatch;
    if (sw == null || !sw.isRunning) return 0;
    return sw.elapsedMilliseconds / 1000;
  }

  void _tickWhileRecording() {
    if (!_isRecording || _recordingStopwatch == null || !mounted) return;
    final sec = _elapsedRecordingSec();
    final cut =
        VoiceRecordLimits.maxSeconds - VoiceRecordLimits.autoStopAdvanceSeconds;
    if (sec >= cut && !_finishingRecording) {
      Future.microtask(() => _finishRecording(autofinishNearMax: true));
      return;
    }
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_busy) return;

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
      await _recorder.start(
        RecordConfig(
          encoder: encoder,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;

      _recordingStopwatch = Stopwatch()..start();
      _recordingTicker?.cancel();
      _recordingTicker = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickWhileRecording(),
      );

      setState(() {
        _busy = false;
        _isRecording = true;
        _encoderUsed = encoder;
        _recordedBytes = null;
        _recordedName = null;
        _recordedDurationSec = null;
      });
    } catch (e) {
      if (!mounted) return;
      _recordingTicker?.cancel();
      _recordingStopwatch = null;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('녹음을 시작할 수 없어요: $e')),
      );
    }
  }

  Future<void> _finishRecording({bool autofinishNearMax = false}) async {
    if (!_isRecording || _finishingRecording) return;
    _finishingRecording = true;
    _recordingTicker?.cancel();
    _recordingTicker = null;

    final sw = _recordingStopwatch;
    sw?.stop();
    final durationSec = sw == null ? 0.0 : sw.elapsedMilliseconds / 1000;
    _recordingStopwatch = null;

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
        _finishingRecording = false;
        return;
      }

      final enc = _encoderUsed ?? await _pickEncoder();
      final ext = _extensionForEncoder(enc);
      final base = _defaultRecordingFileBase();
      final name = '$base.$ext';

      setState(() {
        _recordedBytes = Uint8List.fromList(raw);
        _recordedName = name;
        _recordedDurationSec = durationSec;
      });

      if (autofinishNearMax && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '최대 길이 ${VoiceRecordLimits.maxSeconds}초에 맞춰 녹음을 멈춰 저장했어요. '
              '(${VoiceRecordLimits.minSeconds}초~${VoiceRecordLimits.maxSeconds}초 안내 참고)',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('녹음을 저장할 수 없어요: $e')),
      );
    }
    _finishingRecording = false;
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;
    if (!_isRecording) {
      await _startRecording();
      return;
    }
    await _finishRecording(autofinishNearMax: false);
  }

  String _defaultRecordingFileBase() {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '녹음_$stamp';
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
    var bytes = _recordedBytes;
    final filename = _recordedName;
    var dur = _recordedDurationSec;
    if (bytes == null || filename == null || dur == null) return;

    final trimmed = WavDurationTrim.trimToMaxKeepingTail(
      wavBytes: bytes,
      minSeconds: VoiceRecordLimits.minSeconds,
      maxSeconds: VoiceRecordLimits.maxSeconds,
    );
    if (trimmed != null) {
      bytes = trimmed.bytes;
      dur = trimmed.durationSeconds;
    }

    if (dur < VoiceRecordLimits.minSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최소 ${VoiceRecordLimits.minSeconds}초 이상 말해야 서버에서 인정돼요. '
            '(현재 ${dur.toStringAsFixed(1)}초)',
          ),
        ),
      );
      return;
    }

    final nameForApi = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    final request = VoiceUploadRequest(
      filename: filename,
      bytes: bytes,
      folderId: _folderId,
      name: nameForApi,
    );
    Navigator.of(context).pop<VoiceUploadRequest>(request);
  }

  bool get _canUpload {
    final recorded = _recordedBytes != null;
    final dur = _recordedDurationSec;
    if (!recorded || _busy || dur == null) return false;
    return dur >= VoiceRecordLimits.minSeconds;
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

  static String _fmtMmSs(double sec) {
    final s = sec.floor().clamp(0, 5999);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final folders = _orderedFolders();
    final recorded = _recordedBytes != null;
    final elapsed = _isRecording ? _elapsedRecordingSec() : 0.0;
    final progress = (elapsed / VoiceRecordLimits.maxSeconds).clamp(0.0, 1.0);
    final untilAuto = VoiceRecordLimits.maxSeconds -
        VoiceRecordLimits.autoStopAdvanceSeconds -
        elapsed;

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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: YeolpumtaTheme.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YeolpumtaTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: YeolpumtaTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '녹음 길이 안내',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '· 최소 ${VoiceRecordLimits.minSeconds}초 이상 말해 주세요 (짧으면 등록이 안 돼요)\n'
                    '· 최대 ${VoiceRecordLimits.maxSeconds}초까지 업로드돼요 (넘으면 앞부분을 잘라 최근 구간만 사용)',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${VoiceRecordLimits.maxSeconds}초에 자동으로 녹음이 멈춰요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            if (_isRecording) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: YeolpumtaTheme.divider,
                  color: untilAuto <= 5
                      ? Colors.orange.shade600
                      : YeolpumtaTheme.accent,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtMmSs(elapsed),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '/ ${_fmtMmSs(VoiceRecordLimits.maxSeconds.toDouble())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (untilAuto <= 5 && untilAuto > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '곧 자동으로 멈춰요 · 남은 약 ${untilAuto.toStringAsFixed(1)}초',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ],
            if (recorded && _recordedName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: YeolpumtaTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '파일 · ${_recordedName!}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: YeolpumtaTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '길이 ${_recordedDurationSec == null ? '—' : '${_recordedDurationSec!.toStringAsFixed(1)}초'} '
                      '(최소 ${VoiceRecordLimits.minSeconds}초)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: (_recordedDurationSec ?? 0) >=
                                VoiceRecordLimits.minSeconds
                            ? YeolpumtaTheme.textSecondary
                            : Colors.orange.shade800,
                      ),
                    ),
                    if ((_recordedDurationSec ?? 0) < VoiceRecordLimits.minSeconds)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '아직 짧아요. 다시 녹음해 주세요.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                  ],
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
                  onPressed: _busy || _isRecording ? null : _submitNewFolder,
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canUpload ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: YeolpumtaTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _canUpload ? '이 폴더에 올리기' : '이 폴더에 올리기 (최소 ${VoiceRecordLimits.minSeconds}초 필요)',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
