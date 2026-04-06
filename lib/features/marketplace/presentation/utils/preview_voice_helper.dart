import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 구매자·판매자 공통: 약 N초만 TTS 재생 (실제 서비스에서는 학습 음색으로 교체)
class PreviewVoiceHelper {
  PreviewVoiceHelper() : _tts = FlutterTts();

  final FlutterTts _tts;
  Timer? _timer;
  bool _inited = false;

  Future<void> ensureInit() async {
    if (_inited) return;
    await _tts.setLanguage('ko-KR');
    if (!kIsWeb) {
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
    }
    _inited = true;
  }

  /// [seconds] 후 강제 중지 — 구매 전 미리듣기 용도
  Future<void> playPreview(String text, {int seconds = 5}) async {
    await ensureInit();
    await stop();
    final t = text.trim();
    if (t.isEmpty) return;
    _timer = Timer(Duration(seconds: seconds), () {
      _tts.stop();
    });
    await _tts.speak(t);
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _tts.stop();
  }

  void dispose() {
    _timer?.cancel();
    _tts.stop();
  }
}
