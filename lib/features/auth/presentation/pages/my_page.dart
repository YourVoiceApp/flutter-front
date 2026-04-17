import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/user_profile.dart';
import '../../../voices/data/voice_library_repository.dart';
import '../../../voices/domain/voice_folder.dart';
import '../../../voices/domain/voice_job.dart';
import '../../../voices/presentation/widgets/voice_job_list_card.dart';
import 'account_detail_page.dart';

/// 프로필 + 보유 음성(출처별) — 데모
class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
    required this.repository,
    required this.profileRepository,
    required this.folders,
    required this.onAdvanceDemo,
    required this.onDeleteJob,
    required this.onMoveJob,
    this.isGuestMode = false,
    this.onListenTap,
    this.onRequireLogin,
    this.onAccountDeleted,
  });

  final VoiceLibraryRepository repository;
  final UserProfileRepository profileRepository;
  final List<VoiceFolder> folders;
  final Future<void> Function(String id) onAdvanceDemo;
  final Future<void> Function(String id) onDeleteJob;
  final Future<void> Function(String jobId, String folderId) onMoveJob;
  final bool isGuestMode;

  /// 음성 카드 탭 → 듣기 (없으면 카드 탭 무반응)
  final void Function(VoiceJob job)? onListenTap;
  final Future<void> Function()? onRequireLogin;
  final VoidCallback? onAccountDeleted;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<VoiceJob> _jobs = [];
  UserProfile? _profile;
  bool _loading = true;
  VoiceOrigin? _originFilter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final snap = await widget.repository.load();
    final prof = await widget.profileRepository.loadProfile();
    if (!mounted) return;
    setState(() {
      _jobs = snap.jobs;
      _profile = prof;
      _loading = false;
    });
  }

  Future<void> _openAccountDetail() async {
    if (widget.isGuestMode || _profile == null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('게스트 모드에서는 계정 정보가 없어요. 로그인 후 이용해 주세요.'),
          action: widget.onRequireLogin == null
              ? null
              : SnackBarAction(
                  label: '로그인',
                  onPressed: () {
                    widget.onRequireLogin!.call();
                  },
                ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            AccountDetailPage(onAccountDeleted: widget.onAccountDeleted),
      ),
    );
    await _reload();
  }

  String _folderName(String folderId) {
    try {
      return widget.folders.firstWhere((f) => f.id == folderId).name;
    } catch (_) {
      return '폴더';
    }
  }

  List<VoiceFolder> get _sortedFolders {
    final list = List<VoiceFolder>.from(widget.folders);
    list.sort((a, b) {
      if (a.id == VoiceFolder.uncategorizedId) return -1;
      if (b.id == VoiceFolder.uncategorizedId) return 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  int _count(VoiceOrigin? o) {
    if (o == null) return _jobs.length;
    return _jobs.where((j) => j.origin == o).length;
  }

  List<VoiceJob> get _visible {
    var list = List<VoiceJob>.from(_jobs);
    if (_originFilter != null) {
      list = list.where((j) => j.origin == _originFilter).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _showMoveSheet(VoiceJob job) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '옮길 폴더',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._sortedFolders.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    trailing: job.folderId == f.id
                        ? const Icon(Icons.check, color: YeolpumtaTheme.accent)
                        : null,
                    onTap: () => Navigator.pop(ctx, f.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (id != null && id != job.folderId) {
      await widget.onMoveJob(job.id, id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(title: const Text('마이페이지')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  YeolpumtaTheme.accentSoft,
                                  YeolpumtaTheme.surface,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: YeolpumtaTheme.divider),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: YeolpumtaTheme.accent.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 34,
                                    color: YeolpumtaTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.isGuestMode
                                            ? '게스트'
                                            : _profile?.nickname ?? '프로필 없음',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.4,
                                          color: YeolpumtaTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.isGuestMode
                                            ? '로그인 없이 둘러보는 중이에요'
                                            : _profile?.email ??
                                                  '회원가입 시 계정이 저장돼요',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: YeolpumtaTheme.textSecondary
                                              .withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _openAccountDetail,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '계정 정보',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: YeolpumtaTheme
                                                  .textSecondary
                                                  .withValues(alpha: 0.88),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                widget.isGuestMode
                                                    ? '로그인하기'
                                                    : '상세보기',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      widget.isGuestMode ||
                                                          _profile != null
                                                      ? YeolpumtaTheme.accent
                                                      : YeolpumtaTheme
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.45,
                                                            ),
                                                ),
                                              ),
                                              Icon(
                                                widget.isGuestMode
                                                    ? Icons.login_rounded
                                                    : Icons
                                                          .chevron_right_rounded,
                                                size: 20,
                                                color:
                                                    widget.isGuestMode ||
                                                        _profile != null
                                                    ? YeolpumtaTheme.accent
                                                    : YeolpumtaTheme
                                                          .textSecondary
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            '보유 음성',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: YeolpumtaTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '출처에 따라 정리돼요. 음성 탭에서도 같은 구분이 보여요.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: YeolpumtaTheme.textSecondary.withValues(
                                alpha: 0.92,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _OriginStatCard(
                                  origin: null,
                                  count: _count(null),
                                  selected: _originFilter == null,
                                  onTap: () =>
                                      setState(() => _originFilter = null),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OriginStatCard(
                                  origin: VoiceOrigin.uploaded,
                                  count: _count(VoiceOrigin.uploaded),
                                  selected:
                                      _originFilter == VoiceOrigin.uploaded,
                                  onTap: () => setState(
                                    () => _originFilter = VoiceOrigin.uploaded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _OriginStatCard(
                                  origin: VoiceOrigin.sharedRoom,
                                  count: _count(VoiceOrigin.sharedRoom),
                                  selected:
                                      _originFilter == VoiceOrigin.sharedRoom,
                                  onTap: () => setState(
                                    () =>
                                        _originFilter = VoiceOrigin.sharedRoom,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OriginStatCard(
                                  origin: VoiceOrigin.purchased,
                                  count: _count(VoiceOrigin.purchased),
                                  selected:
                                      _originFilter == VoiceOrigin.purchased,
                                  onTap: () => setState(
                                    () => _originFilter = VoiceOrigin.purchased,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: YeolpumtaTheme.textSecondary.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _jobs.isEmpty
                                    ? '아직 보유한 음성이 없어요'
                                    : '이 출처에 해당하는 음성이 없어요',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: YeolpumtaTheme.textSecondary
                                      .withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                      sliver: SliverList.separated(
                        itemCount: _visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final j = _visible[i];
                          return VoiceJobListCard(
                            job: j,
                            folderLabel: _folderName(j.folderId),
                            showFolderLine: true,
                            onAdvance: () async {
                              await widget.onAdvanceDemo(j.id);
                              await _reload();
                            },
                            onDelete: () async {
                              await widget.onDeleteJob(j.id);
                              await _reload();
                            },
                            onMove: () => _showMoveSheet(j),
                            onCardTap: widget.onListenTap != null
                                ? () => widget.onListenTap!(j)
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _OriginStatCard extends StatelessWidget {
  const _OriginStatCard({
    required this.count,
    required this.selected,
    required this.onTap,
    this.origin,
  });

  final VoiceOrigin? origin;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = origin == null ? '전체' : origin!.label;
    final style = origin == null ? null : VoiceOriginStyle.of(origin!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? (style?.tint ?? YeolpumtaTheme.accentSoft)
                : YeolpumtaTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? (style?.accent ?? YeolpumtaTheme.accent).withValues(
                      alpha: 0.45,
                    )
                  : YeolpumtaTheme.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (origin != null)
                    Icon(style!.icon, size: 18, color: style.accent)
                  else
                    Icon(
                      Icons.layers_rounded,
                      size: 18,
                      color: YeolpumtaTheme.textSecondary.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: origin != null
                          ? style!.accent
                          : YeolpumtaTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
