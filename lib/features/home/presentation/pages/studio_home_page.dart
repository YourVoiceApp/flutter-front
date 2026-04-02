import 'package:flutter/material.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';

class StudioHomePage extends StatelessWidget {
  const StudioHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FF),
        scrolledUnderElevation: 0,
        title: const Text('Voice Studio'),
        actions: [
          IconButton(
            onPressed: () => showToast(context, '알림 기능 연결 예정'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _voiceOverviewCard(context),
          const SizedBox(height: 16),
          sectionTitle('핵심 작업'),
          const SizedBox(height: 10),
          quickActionTile(
            context: context,
            icon: Icons.file_upload_outlined,
            title: '샘플 음성 업로드',
            subtitle: '내 목소리 또는 타겟 음성 파일 추가',
            trailing: '추가',
            onTap: () => showToast(context, '업로드 API 연결 예정'),
          ),
          quickActionTile(
            context: context,
            icon: Icons.graphic_eq_rounded,
            title: '보이스 모델 생성',
            subtitle: '업로드한 샘플로 음색 학습 시작',
            trailing: '시작',
            onTap: () => showToast(context, '학습 API 연결 예정'),
          ),
          quickActionTile(
            context: context,
            icon: Icons.edit_note_rounded,
            title: '텍스트 작성 및 생성',
            subtitle: '문장을 입력하고 선택한 목소리로 생성',
            trailing: '작성',
            onTap: () => showToast(context, '변환 API 연결 예정'),
          ),
          const SizedBox(height: 16),
          sectionTitle('최근 생성'),
          const SizedBox(height: 10),
          _recentOutputCard(context),
        ],
      ),
    );
  }
}

Widget _voiceOverviewCard(BuildContext context) {
  return WhiteCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '나의 보이스 모델',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF3B6AF5),
                child: Icon(Icons.record_voice_over_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kim_voice_v1',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '샘플 3개 · 학습 완료 · 품질 좋음',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showToast(context, '새 음성 만들기'),
                icon: const Icon(Icons.add),
                label: const Text('새 보이스'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6AF5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showToast(context, '보이스 미리듣기'),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('미리듣기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3159D7),
                  side: const BorderSide(color: Color(0xFFBFD0FF)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _recentOutputCard(BuildContext context) {
  return WhiteCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '안내 멘트 샘플',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '"안녕하세요, 주문하신 상품이 오늘 도착 예정입니다."',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showToast(context, '음성 재생'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('재생'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showToast(context, '텍스트 수정'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('문장 수정'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6AF5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
