import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/voice_cute_leading_art.dart';
import '../../data/voice_library_repository.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_job.dart';

/// 음성 탭에서 열림 — 「음성 선택」으로 보유 음성을 고른 뒤, 완료된 음성만 TTS 재생
class VoiceListenPage extends StatefulWidget {
  const VoiceListenPage({
    super.key,
    required this.initialJob,
    required this.allJobs,
    this.folders = const [],
    this.adsRemoved = false,
    this.onOpenAdsRemoval,
  });

  final VoiceJob initialJob;

  /// 전체 음성(최신순 권장) — 선택 시트에 표시
  final List<VoiceJob> allJobs;
  final List<VoiceFolder> folders;

  final bool adsRemoved;
  final Future<void> Function()? onOpenAdsRemoval;

  @override
  State<VoiceListenPage> createState() => _VoiceListenPageState();
}

class _VoiceListenPageState extends State<VoiceListenPage> {
  VoiceJob? _selected;

  @override
  void initState() {
    super.initState();
    final list = widget.allJobs;
    if (list.isEmpty) return;
    VoiceJob? match;
    for (final j in list) {
      if (j.id == widget.initialJob.id) {
        match = j;
        break;
      }
    }
    _selected = match ?? list.first;
  }

  Future<void> _openVoicePicker() async {
    final list = widget.allJobs;
    if (list.isEmpty || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
        return SizedBox(
          height: maxH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '보유 음성',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: YeolpumtaTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      color: YeolpumtaTheme.textSecondary,
                      tooltip: '닫기',
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '재생에 쓸 음성을 골라 주세요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, i) {
                    final j = list[i];
                    final sel = _selected?.id == j.id;
                    final (IconData ic, Color col) = switch (j.status) {
                      VoiceJobStatus.completed => (
                          Icons.check_circle_rounded,
                          const Color(0xFF34C759),
                        ),
                      VoiceJobStatus.training => (
                          Icons.auto_awesome_motion_rounded,
                          YeolpumtaTheme.accent,
                        ),
                      VoiceJobStatus.uploaded => (
                          Icons.upload_file_rounded,
                          YeolpumtaTheme.textSecondary,
                        ),
                    };
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            VoiceCuteLeadingAvatar(
                              origin: j.origin,
                              size: 48,
                              borderRadius: 14,
                            ),
                            Positioned(
                              right: -2,
                              bottom: 0,
                              child: Material(
                                color: YeolpumtaTheme.surface,
                                elevation: 1,
                                shadowColor: Colors.black26,
                                shape: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Icon(ic, color: col, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        j.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${j.status.label} · ${j.origin.label} · ${_folderLine(j)}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: YeolpumtaTheme.textSecondary,
                          ),
                        ),
                      ),
                      trailing: sel
                          ? const Icon(
                              Icons.check_rounded,
                              color: YeolpumtaTheme.accent,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selected = j);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _folderLine(VoiceJob j) {
    try {
      final name = widget.folders.firstWhere((f) => f.id == j.folderId).name;
      return '폴더 · $name';
    } catch (_) {
      return '폴더 · 미분류';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.allJobs;

    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('듣기'),
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '올린 음성이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    '「음성 선택」을 누르면 보유 중인 파일 목록에서 고를 수 있어요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                          YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  if (!widget.adsRemoved &&
                      widget.onOpenAdsRemoval != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: YeolpumtaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: widget.onOpenAdsRemoval,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: YeolpumtaTheme.accentSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 22,
                                  color: YeolpumtaTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '듣기 전·후 광고 예정',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: YeolpumtaTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '광고 없이 듣기 · 2,900원',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: YeolpumtaTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '2,900원',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: YeolpumtaTheme.accent,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: YeolpumtaTheme.textSecondary
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (widget.adsRemoved) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color:
                              YeolpumtaTheme.accent.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '광고 제거 적용 중',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: YeolpumtaTheme.accent.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_selected != null) ...[
                    Material(
                      color: YeolpumtaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _openVoicePicker,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  VoiceCuteLeadingAvatar(
                                    origin: _selected!.origin,
                                    size: 52,
                                    borderRadius: 14,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selected!.status ==
                                                  VoiceJobStatus.completed
                                              ? '재생 음성'
                                              : '선택한 음성',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: YeolpumtaTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _selected!.fileName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: YeolpumtaTheme.textPrimary,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: _openVoicePicker,
                                    style: FilledButton.styleFrom(
                                      foregroundColor: YeolpumtaTheme.accent,
                                      backgroundColor:
                                          YeolpumtaTheme.accentSoft,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('음성 선택'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '상태 · ${_selected!.status.label}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selected!.status ==
                                          VoiceJobStatus.completed
                                      ? const Color(0xFF34C759)
                                      : YeolpumtaTheme.textSecondary,
                                ),
                              ),
                              if (widget.folders.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _folderLine(_selected!),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: YeolpumtaTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_selected != null &&
                      _selected!.status == VoiceJobStatus.completed)
                    _ListenComposer(voice: _selected!)
                  else if (_selected != null)
                    _ListenNotReadyHint(status: _selected!.status),
                ],
              ),
            ),
    );
  }
}

class _ListenNotReadyHint extends StatelessWidget {
  const _ListenNotReadyHint({required this.status});

  final VoiceJobStatus status;

  @override
  Widget build(BuildContext context) {
    final msg = switch (status) {
      VoiceJobStatus.uploaded =>
        '이 파일은 아직 학습 전이에요. 음성 탭에서 「다음 단계(데모)」를 눌러 학습을 진행한 뒤 여기서 들을 수 있어요.',
      VoiceJobStatus.training =>
        '학습이 끝나면 이 화면에서 문장 듣기를 쓸 수 있어요. 잠시만 기다려 주세요.',
      VoiceJobStatus.completed => '',
    };
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YeolpumtaTheme.divider),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _ListenComposer extends StatefulWidget {
  const _ListenComposer({required this.voice});

  final VoiceJob voice;

  @override
  State<_ListenComposer> createState() => _ListenComposerState();
}

class _ListenComposerState extends State<_ListenComposer> {
  late final TextEditingController _textCtrl;
  final VoiceLibraryRepository _voiceRepository = VoiceLibraryRepository();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speech = SpeechToText();

  bool _ttsReady = false;
  bool _speechReady = false;
  bool _speaking = false;
  bool _synthesizing = false;
  bool _listening = false;
  String _anchorBeforeMic = '';
  String _speechLocaleId = 'ko_KR';

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _initTts();
    _initSpeech();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      if (!kIsWeb) {
        await _tts.setSpeechRate(0.48);
        await _tts.setVolume(1);
        await _tts.setPitch(1);
      }
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.notListeningStatus ||
            status == SpeechToText.doneStatus) {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.errorMsg)),
          );
        }
      },
    );
    if (!mounted) return;
    if (ok) {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('ko')) {
          _speechLocaleId = l.localeId;
          break;
        }
      }
    }
    if (mounted) setState(() => _speechReady = ok);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spoken = result.recognizedWords;
    final merged = _anchorBeforeMic.isEmpty
        ? spoken
        : '${_anchorBeforeMic.trimRight()} $spoken'.trim();
    _textCtrl.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: merged.length),
    );
  }

  Future<void> _toggleMic() async {
    if (_listening || _speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 인식을 사용할 수 없어요.')),
      );
      return;
    }
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
    _anchorBeforeMic = _textCtrl.text;
    setState(() => _listening = true);
    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: _speechLocaleId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 120),
      );
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _speak() async {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문장을 입력하거나 말로 입력해 주세요.')),
      );
      return;
    }
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
    await _tts.stop();
    await _audioPlayer.stop();
    if (mounted) setState(() => _speaking = true);
    try {
      if (widget.voice.ownershipId != null) {
        setState(() => _synthesizing = true);
        final result = await _voiceRepository.synthesizeSpeech(
          job: widget.voice,
          text: t,
        );
        final bytes = await _voiceRepository.fetchGeneratedAudioBytes(
          result.generatedAudioId,
        );
        await _audioPlayer.play(BytesSource(bytes));
        if (mounted) setState(() => _synthesizing = false);
        return;
      }

      await _tts.speak(t);
    } catch (_) {
      if (mounted) {
        setState(() {
          _speaking = false;
          _synthesizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('재생을 시작할 수 없어요.')),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    _speech.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textCtrl,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText: '읽을 문장을 직접 입력',
            hintStyle: const TextStyle(color: YeolpumtaTheme.textSecondary),
            filled: true,
            fillColor: YeolpumtaTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: YeolpumtaTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: YeolpumtaTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: YeolpumtaTheme.accent,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              tooltip: _listening ? '말 입력 끝' : '말로 입력',
              onPressed: _toggleMic,
              icon: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening
                    ? YeolpumtaTheme.accent
                    : (_speechReady
                        ? YeolpumtaTheme.textSecondary
                        : YeolpumtaTheme.divider),
              ),
            ),
          ),
        ),
        if (_listening)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '듣는 중…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: YeolpumtaTheme.accent,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          widget.voice.ownershipId != null
              ? '「${widget.voice.fileName}」 음성으로 서버 TTS를 요청해 재생합니다.'
              : '「${widget.voice.fileName}」은 기기 TTS로 재생돼요. (게스트/로컬 데이터)',
          style: TextStyle(
            fontSize: 11,
            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed:
                    ((!_ttsReady && widget.voice.ownershipId == null) ||
                        _speaking ||
                        _synthesizing)
                    ? null
                    : _speak,
                style: FilledButton.styleFrom(
                  backgroundColor: YeolpumtaTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_synthesizing ? '생성 중…' : (_speaking ? '재생 중…' : '듣기')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _speaking ? _stop : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: YeolpumtaTheme.divider),
                ),
                child: const Text('중지'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
