import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../domain/room.dart';

/// 공유 음성 「사용」→ (프로필 기준) 문장 직접 입력 또는 마이크로 입력 후 듣기
Future<void> showSharedVoicePlaySheet(
  BuildContext context,
  RoomSharedVoice voice,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF8FAFC),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SharedVoicePlaySheet(voice: voice),
  );
}

class _SharedVoicePlaySheet extends StatefulWidget {
  const _SharedVoicePlaySheet({required this.voice});

  final RoomSharedVoice voice;

  @override
  State<_SharedVoicePlaySheet> createState() => _SharedVoicePlaySheetState();
}

class _SharedVoicePlaySheetState extends State<_SharedVoicePlaySheet> {
  late final TextEditingController _textCtrl;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _ttsReady = false;
  bool _speechReady = false;
  bool _speaking = false;
  bool _listening = false;

  /// 마이크 세션 시작 시점의 텍스트(앞에 붙는 문장)
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
          showToast(context, e.errorMsg);
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
      showToast(context, '음성 인식을 사용할 수 없어요. 마이크·권한·브라우저 설정을 확인해 주세요.');
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
      if (mounted) {
        setState(() => _listening = false);
        showToast(context, '음성 입력을 시작하지 못했어요.');
      }
    }
  }

  Future<void> _speak() async {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) {
      showToast(context, '읽을 문장을 입력하거나 마이크로 말해 주세요.');
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
        showToast(context, '음성 재생을 시작할 수 없어요. (브라우저·기기 설정을 확인해 주세요)');
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFFE07C4C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.voice.voiceTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${widget.voice.ownerName}님이 공유한 음성 프로필',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        if (widget.voice.subtitle != null &&
                            widget.voice.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.voice.subtitle!,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '저장된 문장을 불러오는 게 아니라, 이 음색(프로필)으로 읽힐 내용을 아래에 직접 적거나 말로 입력해요. '
                '재생은 기기 TTS이며, 이후 서버와 연결하면 이 프로필 음색에 맞출 수 있어요.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textCtrl,
                maxLines: 6,
                minLines: 3,
                decoration: fieldDecoration(
                  hint: '이 음성으로 읽을 문장을 직접 쓰거나, 오른쪽 마이크로 말해 입력',
                  icon: Icons.edit_note_rounded,
                  suffix: IconButton(
                    tooltip: _listening ? '말 입력 끝내기' : '말로 입력',
                    onPressed: _toggleMic,
                    icon: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _listening
                          ? const Color(0xFFE07C4C)
                          : (_speechReady
                                ? const Color(0xFF3B6AF5)
                                : const Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              if (_listening) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '듣는 중… 말씀하시면 글자로 반영돼요',
                      style: TextStyle(
                        color: Color(0xFFE07C4C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (!_ttsReady || _speaking) ? null : _speak,
                      icon: Icon(
                        _speaking
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label: Text(_speaking ? '재생 중…' : '듣기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE07C4C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _speaking ? _stop : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('중지'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _ttsReady
                    ? () async {
                        await _stop();
                        await _speak();
                      }
                    : null,
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('처음부터 다시 듣기'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await _speech.stop();
                    await _stop();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
