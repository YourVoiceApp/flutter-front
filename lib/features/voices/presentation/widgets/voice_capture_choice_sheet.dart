import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';

/// 음성 탭 첫 화면에서 「음성 녹음」을 눌렀을 때 업로드 vs 직접 녹음 선택
enum VoiceCaptureChoice {
  upload,
  record,
}

class VoiceCaptureChoiceSheet extends StatelessWidget {
  const VoiceCaptureChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
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
          const SizedBox(height: 18),
          const Text(
            '음성 추가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: YeolpumtaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '파일을 올리거나, 지금 바로 녹음할 수 있어요.',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: YeolpumtaTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: YeolpumtaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YeolpumtaTheme.divider),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            title: const Text(
              '음성 파일 업로드',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
            subtitle: const Text(
              '이미 있는 .wav / .mp3 파일을 골라요',
              style: TextStyle(
                fontSize: 13,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            onTap: () =>
                Navigator.of(context).pop(VoiceCaptureChoice.upload),
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: YeolpumtaTheme.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: YeolpumtaTheme.accent,
              ),
            ),
            title: const Text(
              '직접 녹음',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
            subtitle: const Text(
              '기기 마이크로 바로 녹음해요',
              style: TextStyle(
                fontSize: 13,
                color: YeolpumtaTheme.textSecondary,
              ),
            ),
            onTap: () =>
                Navigator.of(context).pop(VoiceCaptureChoice.record),
          ),
        ],
      ),
    );
  }
}
