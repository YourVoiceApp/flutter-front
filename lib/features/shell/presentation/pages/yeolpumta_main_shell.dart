import 'package:flutter/material.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_profile_repository.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/my_page.dart';
import '../../../marketplace/presentation/pages/market_hub_page.dart';
import '../../../monetization/data/premium_repository.dart';
import '../../../monetization/presentation/pages/ads_removal_paywall_page.dart';
import '../../../rooms/presentation/pages/room_hub_page.dart';
import '../../../shared/presentation/pages/placeholder_page.dart';
import '../../../voices/data/voice_library_repository.dart';
import '../../../voices/domain/voice_job.dart';
import '../../../voices/presentation/pages/voice_listen_page.dart';
import '../../../voices/presentation/pages/voice_pipeline_page.dart';
import '../../../voices/presentation/widgets/voice_folder_manage_sheet.dart';
import '../../../voices/presentation/widgets/voice_upload_sheet.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

/// 핵심만: 음성 · 함께 · 마켓 (듣기는 음성 카드에서)
class YeolpumtaMainShell extends StatefulWidget {
  const YeolpumtaMainShell({super.key});

  @override
  State<YeolpumtaMainShell> createState() => _YeolpumtaMainShellState();
}

class _YeolpumtaMainShellState extends State<YeolpumtaMainShell> {
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final VoiceLibraryRepository _repo = VoiceLibraryRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final PremiumRepository _premiumRepo = PremiumRepository();
  VoiceLibrarySnapshot _data =
      const VoiceLibrarySnapshot(folders: [], jobs: []);
  UserProfile? _profile;
  bool _ready = false;
  bool _adsRemoved = false;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final s = await _repo.load();
    final ads = await _premiumRepo.isAdsRemoved();
    final profile = await _profileRepo.loadProfile();
    if (!mounted) return;
    setState(() {
      _data = s;
      _profile = profile;
      _adsRemoved = ads;
      _ready = true;
    });
  }

  List<VoiceJob> get _completed => _data.jobs
      .where((j) => j.status == VoiceJobStatus.completed)
      .toList();

  Future<String> _createFolderForUpload(String name) async {
    final next = await _repo.createFolder(_data, name);
    if (!mounted) throw StateError('unmounted');
    setState(() => _data = next);
    return next.folders.last.id;
  }

  Future<void> _openUpload([String? initialFolderId]) async {
    final job = await showModalBottomSheet<VoiceJob?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => VoiceUploadSheet(
        folders: _data.folders,
        initialFolderId: initialFolderId,
        onCreateFolder: _createFolderForUpload,
      ),
    );
    if (job == null || !mounted) return;
    final next = await _repo.addJob(_data, job);
    if (!mounted) return;
    setState(() => _data = next);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('올렸어요. 학습은 「다음 단계」로 옮겨 볼 수 있어요.')),
    );
  }

  Future<void> _openFolderManage() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => VoiceFolderManageSheet(
        folders: _data.folders,
        onCreate: (name) async {
          final snap = await _repo.createFolder(_data, name);
          if (!mounted) return;
          setState(() => _data = snap);
        },
        onRename: (id, newName) async {
          final snap = await _repo.renameFolder(_data, id, newName);
          if (!mounted) return;
          setState(() => _data = snap);
        },
        onDelete: (id) async {
          final snap = await _repo.deleteFolder(_data, id);
          if (!mounted) return;
          setState(() => _data = snap);
        },
      ),
    );
  }

  Future<void> _advanceDemo(String id) async {
    final j = _data.jobs.firstWhere((e) => e.id == id);
    final nextStatus = switch (j.status) {
      VoiceJobStatus.uploaded => VoiceJobStatus.training,
      VoiceJobStatus.training => VoiceJobStatus.completed,
      VoiceJobStatus.completed => VoiceJobStatus.completed,
    };
    final updated = j.copyWith(status: nextStatus);
    final snap = await _repo.updateJob(_data, updated);
    if (!mounted) return;
    setState(() => _data = snap);
  }

  Future<void> _deleteJob(String id) async {
    final snap = await _repo.deleteJob(_data, id);
    if (!mounted) return;
    setState(() => _data = snap);
  }

  Future<void> _moveJob(String jobId, String folderId) async {
    final snap = await _repo.moveJobToFolder(_data, jobId, folderId);
    if (!mounted) return;
    setState(() => _data = snap);
  }

  void _openListen(VoiceJob job) {
    final sorted = List<VoiceJob>.from(_data.jobs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VoiceListenPage(
          initialJob: job,
          allJobs: sorted,
          folders: _data.folders,
          adsRemoved: _adsRemoved,
          onOpenAdsRemoval: _openAdsRemovalFromListen,
        ),
      ),
    );
  }

  Future<void> _openAdsRemovalFromListen() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdsRemovalPaywallPage(repository: _premiumRepo),
      ),
    );
    final v = await _premiumRepo.isAdsRemoved();
    if (!mounted) return;
    setState(() => _adsRemoved = v || ok == true);
  }

  Future<void> _openFromDrawer(Future<void> Function() fn) async {
    Navigator.of(context).pop();
    await fn();
  }

  Future<void> _goMyPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MyPage(
          repository: _repo,
          profileRepository: _profileRepo,
          folders: _data.folders,
          onAdvanceDemo: _advanceDemo,
          onDeleteJob: _deleteJob,
          onMoveJob: _moveJob,
          onListenTap: _openListen,
          onAccountDeleted: () {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    final profile = await _profileRepo.loadProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _goSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PlaceholderPage(
          title: '설정',
          message: '알림·테마·계정·약관 (UI 데모)',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['음성', '함께', '마켓'];

    if (!_ready) {
      return const Scaffold(
        backgroundColor: YeolpumtaTheme.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _shellKey,
      backgroundColor: YeolpumtaTheme.bg,
      drawer: Drawer(
        backgroundColor: YeolpumtaTheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  color: YeolpumtaTheme.bg,
                  border: Border(
                    bottom: BorderSide(color: YeolpumtaTheme.divider),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: YeolpumtaTheme.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: YeolpumtaTheme.accent,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Your Voice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: YeolpumtaTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile == null
                          ? '로그인 유지 중'
                          : '${_profile!.nickname} · ${_profile!.email}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.account_circle_outlined,
                        color: YeolpumtaTheme.textPrimary,
                      ),
                      title: const Text(
                        '마이페이지',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _openFromDrawer(_goMyPage),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: YeolpumtaTheme.textPrimary,
                      ),
                      title: const Text(
                        '설정',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _openFromDrawer(_goSettings),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.help_outline_rounded,
                        color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                      ),
                      title: Text(
                        '고객센터',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color:
                              YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                      onTap: () => _openFromDrawer(() async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const PlaceholderPage(
                              title: '고객센터',
                              message: '문의·FAQ (UI 데모)',
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                ),
                title: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
                onTap: () => _openFromDrawer(_logout),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          color: YeolpumtaTheme.textPrimary,
          tooltip: '메뉴',
          onPressed: () => _shellKey.currentState?.openDrawer(),
        ),
        title: Text(titles[_index.clamp(0, titles.length - 1)]),
      ),
      body: IndexedStack(
        index: _index.clamp(0, 2),
        children: [
          VoicePipelinePage(
            jobs: _data.jobs,
            folders: _data.folders,
            onUploadTap: _openUpload,
            onOpenFolderManage: _openFolderManage,
            onAdvanceDemo: _advanceDemo,
            onDeleteJob: _deleteJob,
            onMoveJob: _moveJob,
            onListenTap: _openListen,
          ),
          const RoomHubPage(embeddedInMainShell: true),
          MarketHubPage(
            completedJobs: _completed,
            premiumRepository: _premiumRepo,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, 2),
        onDestinationSelected: (i) async {
          setState(() => _index = i.clamp(0, 2));
          final v = await _premiumRepo.isAdsRemoved();
          if (mounted) setState(() => _adsRemoved = v);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.audio_file_outlined),
            selectedIcon: Icon(Icons.audio_file_rounded),
            label: '음성',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: '함께',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: '마켓',
          ),
        ],
      ),
    );
  }
}
