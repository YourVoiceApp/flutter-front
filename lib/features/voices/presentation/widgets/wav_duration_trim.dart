import 'dart:typed_data';

class WavDurationTrimResult {
  const WavDurationTrimResult({
    required this.bytes,
    required this.durationSeconds,
    required this.trimmedFromStart,
  });

  final Uint8List bytes;
  final double durationSeconds;
  final bool trimmedFromStart;
}

/// Minimal WAV(PCM) parser/trimmer for upload-time duration limits.
abstract final class WavDurationTrim {
  static WavDurationTrimResult? trimToMaxKeepingTail({
    required Uint8List wavBytes,
    required int minSeconds,
    required int maxSeconds,
  }) {
    if (wavBytes.length < 44) return null;
    if (!_matchAscii(wavBytes, 0, 'RIFF') || !_matchAscii(wavBytes, 8, 'WAVE')) {
      return null;
    }

    final dataOffset = _findChunkDataOffset(wavBytes, 'data');
    final fmtOffset = _findChunkDataOffset(wavBytes, 'fmt ');
    if (dataOffset == null || fmtOffset == null) return null;

    final bitsPerSample = _u16le(wavBytes, fmtOffset + 14);
    final channels = _u16le(wavBytes, fmtOffset + 2);
    final sampleRate = _u32le(wavBytes, fmtOffset + 4);
    if (bitsPerSample <= 0 || channels <= 0 || sampleRate <= 0) return null;

    final bytesPerSample = bitsPerSample ~/ 8;
    if (bytesPerSample <= 0) return null;
    final blockAlign = channels * bytesPerSample;
    if (blockAlign <= 0) return null;

    final dataSize = _u32le(wavBytes, dataOffset - 4);
    final dataStart = dataOffset;
    final dataEnd = dataStart + dataSize;
    if (dataEnd > wavBytes.length || dataSize <= 0) return null;

    final totalSamples = dataSize ~/ blockAlign;
    final duration = totalSamples / sampleRate;
    if (duration < minSeconds) {
      return WavDurationTrimResult(
        bytes: wavBytes,
        durationSeconds: duration,
        trimmedFromStart: false,
      );
    }

    final maxSamples = maxSeconds * sampleRate;
    if (totalSamples <= maxSamples) {
      return WavDurationTrimResult(
        bytes: wavBytes,
        durationSeconds: duration,
        trimmedFromStart: false,
      );
    }

    final keepSamples = maxSamples;
    final keepBytes = keepSamples * blockAlign;
    final trimmedStart = dataEnd - keepBytes;
    final out = Uint8List.fromList(wavBytes);
    out.setRange(dataStart, dataStart + keepBytes, wavBytes, trimmedStart);
    _writeU32le(out, dataOffset - 4, keepBytes);
    _writeU32le(out, 4, 36 + keepBytes);

    return WavDurationTrimResult(
      bytes: out.sublist(0, dataStart + keepBytes),
      durationSeconds: keepSamples / sampleRate,
      trimmedFromStart: true,
    );
  }

  static int? _findChunkDataOffset(Uint8List bytes, String chunkName) {
    var p = 12;
    while (p + 8 <= bytes.length) {
      final nameOk = _matchAscii(bytes, p, chunkName);
      final size = _u32le(bytes, p + 4);
      final dataOffset = p + 8;
      if (nameOk) return dataOffset;
      p = dataOffset + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }

  static bool _matchAscii(Uint8List bytes, int offset, String text) {
    if (offset < 0 || offset + text.length > bytes.length) return false;
    for (var i = 0; i < text.length; i++) {
      if (bytes[offset + i] != text.codeUnitAt(i)) return false;
    }
    return true;
  }

  static int _u16le(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 2 > bytes.length) return 0;
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  static int _u32le(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) return 0;
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static void _writeU32le(Uint8List bytes, int offset, int value) {
    if (offset < 0 || offset + 4 > bytes.length) return;
    bytes[offset] = value & 0xff;
    bytes[offset + 1] = (value >> 8) & 0xff;
    bytes[offset + 2] = (value >> 16) & 0xff;
    bytes[offset + 3] = (value >> 24) & 0xff;
  }
}
