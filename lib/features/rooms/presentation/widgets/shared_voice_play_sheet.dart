import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../voices/data/voice_library_repository.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';

/// 공유 음성 「사용」→ 다운로드 허용 공유는 claim 후 보유 음성과 동일하게
/// `POST /voices/{ownershipId}/text-to-speech` 를 사용합니다. 미로그인은 기기 TTS.
Future<void> showSharedVoicePlaySheet(
  BuildContext context, {
  required String roomId,
  required RoomSharedVoice voice,
  List<VoiceJob> libraryJobs = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YeolpumtaTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SharedVoicePlaySheet(
      roomId: roomId,
      voice: voice,
      libraryJobs: libraryJobs,
    ),
  );
}

class _SharedVoicePlaySheet extends StatefulWidget {
  const _SharedVoicePlaySheet({
    required this.roomId,
    required this.voice,
    this.libraryJobs = const [],
  });

  final String roomId;
  final RoomSharedVoice voice;
  final List<VoiceJob> libraryJobs;

  @override
  State<_SharedVoicePlaySheet> createState() => _SharedVoicePlaySheetState();
}

class _SharedVoicePlaySheetState extends State<_SharedVoicePlaySheet> {
  late final TextEditingController _textCtrl;
  final RoomRepository _roomRepository = RoomRepository();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speech = SpeechToText();

  bool _ttsReady = false;
  bool _speechReady = false;
  bool _speaking = false;
  bool _listening = false;
  bool _synthesizing = false;
  bool _claiming = false;
  VoiceJob? _claimedJob;

  /// 마이크 세션 시작 시점의 텍스트(앞에 붙는 문장)
  String _anchorBeforeMic = '';

  String _speechLocaleId = 'ko_KR';

  /// `null`: 아직 확인 전 · `true`: 세션 있음(서버 합성 가능)
  bool? _hasRemoteSession;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _refreshRemoteSession();
    _initTts();
    _initSpeech();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _refreshRemoteSession() async {
    final v = await _roomRepository.usesRemote;
    if (mounted) setState(() => _hasRemoteSession = v);
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
    await _audioPlayer.stop();
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
    await _audioPlayer.stop();

    Future<void> playDeviceTts() async {
      if (mounted) setState(() => _speaking = true);
      try {
        await _tts.speak(t);
      } catch (_) {
        if (mounted) {
          setState(() => _speaking = false);
          showToast(context, '음성 재생을 시작할 수 없어요.');
        }
      }
    }

    Future<VoiceSynthesisResult> requestSynthesis() async {
      final oid = await _ensureOwnershipIdForServer();
      if (oid == null) {
        throw StateError('내 음성에 추가할 수 있는 공유만 서버 음색으로 합성할 수 있어요.');
      }
      return _roomRepository.synthesizeOwnedVoiceSpeech(
        ownershipId: oid,
        text: t,
      );
    }

    Future<void> playServerSynth() async {
      if (mounted) setState(() => _synthesizing = true);
      try {
        final result = await requestSynthesis();
        final bytes = await _roomRepository.fetchSynthesizedAudioBytes(result);
        if (!mounted) return;
        if (mounted) {
          setState(() {
            _synthesizing = false;
            _speaking = true;
          });
        }
        await _audioPlayer.play(BytesSource(bytes));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _speaking = false;
          _synthesizing = false;
        });
        showToast(context, '서버 음색 합성에 실패했어요. ($e)');
        await playDeviceTts();
        return;
      }
    }

    final remote = await _roomRepository.usesRemote;
    if (!mounted) return;
    setState(() => _hasRemoteSession = remote);
    if (remote && _canUseServerVoice) {
      await playServerSynth();
    } else {
      if (remote && !_canUseServerVoice) {
        showToast(context, '듣기 전용 공유는 내 음성에 추가할 수 없어 기기 목소리로 재생해요.');
      }
      await playDeviceTts();
    }
  }

  int? _resolvedOwnershipId() {
    final fromClaim = _claimedJob?.ownershipId;
    if (fromClaim != null && fromClaim > 0) return fromClaim;

    final fromShare = widget.voice.ownershipId;
    if (fromShare != null && fromShare > 0) return fromShare;

    final ext = widget.voice.externalVoiceId.trim();
    final vk = (widget.voice.voiceKey ?? '').trim();
    for (final job in widget.libraryJobs) {
      final oid = job.ownershipId;
      if (oid == null || oid <= 0) continue;
      if (job.id == ext || (vk.isNotEmpty && job.id == vk)) {
        return oid;
      }
    }
    return null;
  }

  bool get _canUseServerVoice =>
      _resolvedOwnershipId() != null ||
      widget.voice.accessScope == RoomVoiceAccessScope.downloadAllowed;

  Future<int?> _ensureOwnershipIdForServer({bool showSuccess = false}) async {
    final existing = _resolvedOwnershipId();
    if (existing != null) return existing;

    if (widget.voice.accessScope != RoomVoiceAccessScope.downloadAllowed) {
      return null;
    }

    if (mounted) setState(() => _claiming = true);
    try {
      final claimed = await _roomRepository.claimRoomSharedVoice(
        roomId: widget.roomId,
        shareId: widget.voice.id,
      );
      final ownershipId = claimed.ownershipId;
      if (ownershipId == null || ownershipId <= 0) {
        throw StateError('클레임 응답에 ownershipId가 없어요.');
      }
      if (!mounted) return ownershipId;
      setState(() => _claimedJob = claimed);
      if (showSuccess) {
        showToast(context, '내 음성에 추가했어요.');
      }
      return ownershipId;
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _claimSharedVoice() async {
    if (widget.voice.accessScope != RoomVoiceAccessScope.downloadAllowed) {
      showToast(context, '이 공유는 듣기 전용이라 내 음성에 추가할 수 없어요.');
      return;
    }
    try {
      await _ensureOwnershipIdForServer(showSuccess: true);
    } catch (e) {
      if (mounted) showToast(context, '내 음성에 추가하지 못했어요. ($e)');
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

  String _playbackScopeHint() {
    final remote = _hasRemoteSession;
    final synthLine = remote == null
        ? '로그인 상태를 확인하는 중이에요.'
        : remote
        ? '내 음성에 추가된 공유는 서버 음색으로 합성해 들려요.'
        : '로그인하면 공유 음색으로 합성해 들을 수 있어요. 지금은 기기 목소리(TTS)로 재생돼요.';
    final scopeLine = switch (widget.voice.accessScope) {
      RoomVoiceAccessScope.listenOnly => '듣기 전용 공유는 내 음성에 추가할 수 없어요.',
      RoomVoiceAccessScope.downloadAllowed =>
        '다운로드 허용 공유는 「내 음성에 추가」 후 TTS에 사용할 수 있어요.',
    };
    return '$synthLine $scopeLine';
  }

  /// 원격 합성이 아닐 때만 기기 TTS 준비가 필요함
  bool get _blockListenUntilTts => _hasRemoteSession != true && !_ttsReady;

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
                    color: YeolpumtaTheme.divider,
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
                      color: YeolpumtaTheme.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: YeolpumtaTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.voice.voiceTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: YeolpumtaTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.voice.ownerName}님이 공유한 음성 프로필',
                          style: TextStyle(
                            color: YeolpumtaTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.voice.subtitle != null &&
                            widget.voice.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.voice.subtitle!,
                              style: TextStyle(
                                color: YeolpumtaTheme.textSecondary,
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
              Text(
                '문장을 직접 적거나 마이크로 입력한 뒤 「듣기」로 확인해요. ${_playbackScopeHint()}',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (widget.voice.accessScope ==
                  RoomVoiceAccessScope.downloadAllowed) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: (_claiming || _synthesizing || _speaking)
                      ? null
                      : _claimSharedVoice,
                  icon: Icon(
                    _resolvedOwnershipId() != null
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    color: YeolpumtaTheme.accent,
                  ),
                  label: Text(
                    _claiming
                        ? '추가 중…'
                        : (_resolvedOwnershipId() != null
                              ? '내 음성에 추가됨'
                              : '내 음성에 추가'),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: YeolpumtaTheme.accent,
                    side: BorderSide(
                      color: YeolpumtaTheme.accent.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
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
                          ? YeolpumtaTheme.accent
                          : (_speechReady
                                ? YeolpumtaTheme.accent.withValues(alpha: 0.75)
                                : YeolpumtaTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              if (_listening) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: YeolpumtaTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '듣는 중… 말씀하시면 글자로 반영돼요',
                      style: TextStyle(
                        color: YeolpumtaTheme.accent,
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
                      onPressed:
                          (_blockListenUntilTts ||
                              _speaking ||
                              _claiming ||
                              _synthesizing)
                          ? null
                          : _speak,
                      icon: Icon(
                        _synthesizing
                            ? Icons.hourglass_top_rounded
                            : (_speaking
                                  ? Icons.graphic_eq_rounded
                                  : Icons.volume_up_rounded),
                      ),
                      label: Text(
                        _synthesizing
                            ? (_claiming ? '추가 중…' : '합성 중…')
                            : (_speaking ? '재생 중…' : '듣기'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: YeolpumtaTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_speaking || _synthesizing) ? _stop : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('중지'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: YeolpumtaTheme.textPrimary,
                        side: const BorderSide(color: YeolpumtaTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed:
                    (!_blockListenUntilTts && !_claiming && !_synthesizing)
                    ? () async {
                        await _stop();
                        await _speak();
                      }
                    : null,
                icon: Icon(
                  Icons.replay_rounded,
                  size: 20,
                  color: YeolpumtaTheme.accent,
                ),
                label: Text(
                  '처음부터 다시 듣기',
                  style: TextStyle(
                    color: YeolpumtaTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  child: Text(
                    '닫기',
                    style: TextStyle(color: YeolpumtaTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
