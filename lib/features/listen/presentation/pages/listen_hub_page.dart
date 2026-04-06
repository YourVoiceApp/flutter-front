import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../voices/domain/voice_folder.dart';
import '../../../voices/domain/voice_job.dart';

/// 완료된 음성만 선택 → 어떤 파일인지 표시 → 문장 입력 → 듣기
class ListenHubPage extends StatefulWidget {
  const ListenHubPage({
    super.key,
    required this.completedJobs,
    this.folders = const [],
    this.adsRemoved = false,
    this.onOpenAdsRemoval,
  });

  final List<VoiceJob> completedJobs;
  final List<VoiceFolder> folders;

  /// 광고 제거 구매 여부 (듣기 구간 광고 안내 숨김)
  final bool adsRemoved;
  final Future<void> Function()? onOpenAdsRemoval;

  @override
  State<ListenHubPage> createState() => _ListenHubPageState();
}

class _ListenHubPageState extends State<ListenHubPage> {
  VoiceJob? _selected;

  @override
  void didUpdateWidget(ListenHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedJobs.isEmpty) {
      _selected = null;
    } else if (_selected == null ||
        !widget.completedJobs.any((e) => e.id == _selected!.id)) {
      _selected = widget.completedJobs.first;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.completedJobs.isNotEmpty) {
      _selected = widget.completedJobs.first;
    }
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
    final list = widget.completedJobs;

    return ColoredBox(
      color: YeolpumtaTheme.bg,
      child: SafeArea(
        child: list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '「음성」에서 학습이 완료된 파일이 있어야\n여기서 들을 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const Text(
                    '듣기',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '어떤 음성으로 읽을지 고르고, 문장을 적거나 말로 입력해요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                  if (!widget.adsRemoved && widget.onOpenAdsRemoval != null) ...[
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
                          color: YeolpumtaTheme.accent.withValues(alpha: 0.9),
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
                  Text(
                    '선택한 음성 파일',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final j in list)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                j.fileName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: _selected?.id == j.id,
                              onSelected: (_) =>
                                  setState(() => _selected = j),
                              selectedColor: YeolpumtaTheme.accentSoft,
                              labelStyle: TextStyle(
                                color: _selected?.id == j.id
                                    ? YeolpumtaTheme.accent
                                    : YeolpumtaTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              side: const BorderSide(
                                color: YeolpumtaTheme.divider,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selected != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YeolpumtaTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: YeolpumtaTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '지금 이 음성으로 재생해요',
                            style: TextStyle(
                              fontSize: 12,
                              color: YeolpumtaTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selected!.fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: YeolpumtaTheme.textPrimary,
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
                  ],
                  const SizedBox(height: 20),
                  if (_selected != null)
                    _ListenComposer(voiceLabel: _selected!.fileName),
                ],
              ),
      ),
    );
  }
}

class _ListenComposer extends StatefulWidget {
  const _ListenComposer({required this.voiceLabel});

  final String voiceLabel;

  @override
  State<_ListenComposer> createState() => _ListenComposerState();
}

class _ListenComposerState extends State<_ListenComposer> {
  late final TextEditingController _textCtrl;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _ttsReady = false;
  bool _speechReady = false;
  bool _speaking = false;
  bool _listening = false;
  String _anchorBeforeMic = '';
  String _speechLocaleId = 'ko_KR';

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _initTts();
    _initSpeech();
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
    if (mounted) setState(() => _speaking = true);
    try {
      await _tts.speak(t);
    } catch (_) {
      if (mounted) {
        setState(() => _speaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('재생을 시작할 수 없어요.')),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _tts.stop();
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
              borderSide: const BorderSide(color: YeolpumtaTheme.accent, width: 1.5),
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
          '「${widget.voiceLabel}」음색은 기기 TTS로 재생돼요. (연결 시 실제 모델로)',
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
                onPressed: (!_ttsReady || _speaking) ? null : _speak,
                style: FilledButton.styleFrom(
                  backgroundColor: YeolpumtaTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_speaking ? '재생 중…' : '듣기'),
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
