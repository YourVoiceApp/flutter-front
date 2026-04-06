import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/market_repository.dart';
import '../utils/preview_voice_helper.dart';

/// 학습 완료 음성 + 미리듣기 문장 + 가격 → 시장 등록
class SellVoiceListingPage extends StatefulWidget {
  const SellVoiceListingPage({
    super.key,
    required this.completedJobs,
    required this.marketRepository,
  });

  final List<VoiceJob> completedJobs;
  final MarketRepository marketRepository;

  @override
  State<SellVoiceListingPage> createState() => _SellVoiceListingPageState();
}

class _SellVoiceListingPageState extends State<SellVoiceListingPage> {
  String? _jobId;
  final _nicknameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _previewCtrl = TextEditingController();
  final _preview = PreviewVoiceHelper();
  bool _busy = false;
  bool _previewPlaying = false;

  static const int _previewMaxChars = 200;

  @override
  void initState() {
    super.initState();
    if (widget.completedJobs.isNotEmpty) {
      _jobId = widget.completedJobs.first.id;
    }
    _nicknameCtrl.text = '내음성스튜디오';
    _previewCtrl.text = '안녕하세요, 이 목소리는 이런 느낌이에요. 구매 전에 미리 들어 보세요.';
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _priceCtrl.dispose();
    _previewCtrl.dispose();
    _preview.dispose();
    super.dispose();
  }

  Future<void> _playSellerPreview() async {
    final t = _previewCtrl.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미리듣기용 문장을 적어 주세요.')),
      );
      return;
    }
    setState(() => _previewPlaying = true);
    try {
      await _preview.playPreview(t, seconds: 5);
    } finally {
      if (mounted) setState(() => _previewPlaying = false);
    }
  }

  Future<void> _submit() async {
    final jobs = widget.completedJobs;
    final id = _jobId;
    VoiceJob? job;
    if (id != null) {
      try {
        job = jobs.firstWhere((e) => e.id == id);
      } catch (_) {}
    }
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('판매할 음성을 선택해 주세요.')),
      );
      return;
    }
    final script = _previewCtrl.text.trim();
    if (script.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('미리듣기 문장을 조금 더 적어 주세요. (약 5초 분량)'),
        ),
      );
      return;
    }
    final raw = _priceCtrl.text.replaceAll(',', '').trim();
    final price = int.tryParse(raw);
    if (price == null || price < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가격은 100원 이상 숫자로 입력해 주세요.')),
      );
      return;
    }
    final nick = _nicknameCtrl.text.trim();
    if (nick.length < 2 || nick.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('크리에이터 닉네임은 2~20자로 적어 주세요.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _preview.stop();
      await widget.marketRepository.addMine(
        fileName: job.fileName,
        priceWon: price,
        sourceVoiceJobId: job.id,
        previewScript: script,
        creatorNickname: nick,
      );
      if (!mounted) return;
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.completedJobs;

    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('음성 판매 등록'),
      ),
      body: jobs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '학습이 완료된 음성이 있어야\n시장에 올릴 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: YeolpumtaTheme.textSecondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  '어떤 파일을',
                  style: TextStyle(
                    fontSize: 14,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YeolpumtaTheme.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _jobId != null &&
                              jobs.any((e) => e.id == _jobId)
                          ? _jobId
                          : (jobs.isNotEmpty ? jobs.first.id : null),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        for (final j in jobs)
                          DropdownMenuItem(
                            value: j.id,
                            child: Text(
                              j.fileName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _jobId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '크리에이터 닉네임',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '마켓에서 검색·표시되는 이름이에요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nicknameCtrl,
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 푸른목소리',
                    counterText: '',
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
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '미리듣기용 문장',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '구매자가 약 5초 동안 들을 예시 문장이에요. 직접 적고 아래에서 재생해 보세요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _previewCtrl,
                  maxLines: 4,
                  maxLength: _previewMaxChars,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) {
                    return Text(
                      '$currentLength / $maxLength · 약 5초 권장',
                      style: TextStyle(
                        fontSize: 11,
                        color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.85),
                      ),
                    );
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 안녕하세요, 이런 톤으로 녹음했어요.',
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
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (_busy || _previewPlaying) ? null : _playSellerPreview,
                  icon: Icon(
                    _previewPlaying ? Icons.stop_circle_outlined : Icons.hearing_rounded,
                    size: 20,
                    color: YeolpumtaTheme.accent,
                  ),
                  label: Text(
                    _previewPlaying ? '재생 중… (5초 후 자동 중지)' : '5초 미리듣기',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.accent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: YeolpumtaTheme.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    '데모는 기기 음성으로 재생돼요. 실제 출시 시 학습된 목소리로 바뀝니다.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '희망 가격',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 5900',
                    suffixText: '원',
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: YeolpumtaTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: YeolpumtaTheme.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '실제 서비스에서는 수수료·환불 규정·저작권 동의를 받은 뒤 결제와 함께 노출합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: YeolpumtaTheme.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '시장에 올리기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
