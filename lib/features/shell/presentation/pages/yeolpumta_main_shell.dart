import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/services/app_services.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_profile_repository.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/my_page.dart';
import '../../../monetization/data/premium_repository.dart';
import '../../../monetization/presentation/pages/ads_removal_paywall_page.dart';
import '../../../monetization/presentation/widgets/app_banner_ad.dart';
import '../../../monetization/presentation/widgets/app_native_ad_card.dart';
import '../../../rooms/presentation/pages/room_hub_page.dart';
import '../../../shared/presentation/pages/placeholder_page.dart';
import '../../../voices/data/voice_library_repository.dart';
import '../../../voices/domain/voice_job.dart';
import '../../../voices/domain/voice_upload_request.dart';
import '../../../voices/presentation/pages/voice_listen_page.dart';
import '../../../voices/presentation/pages/voice_pipeline_page.dart';
import '../../../voices/presentation/widgets/voice_folder_manage_sheet.dart';
import '../../../voices/presentation/widgets/voice_record_sheet.dart';
import '../../../voices/presentation/widgets/voice_upload_sheet.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../onboarding/data/onboarding_prefs.dart';
import '../../../onboarding/presentation/widgets/tab_coach_overlay.dart';

const _kTabCoachGuestHint = '지금은 둘러보기! 로그인하면 풀기능이에요.';

const _tabCoachTitles = <String>['여기가 음성 홈이에요', '함께 탭'];

const _tabCoachBodies = <String>[
  '「음성 녹음」이 시작점이에요. 폴더로 정리도 돼요.',
  '방 만들고 목록에서 들어와요. 안에서는 음성 나눠요.',
];

/// 핵심만: 음성 · 함께 (듣기는 음성 카드에서)
class YeolpumtaMainShell extends StatefulWidget {
  const YeolpumtaMainShell({super.key, this.isGuestMode = false});

  final bool isGuestMode;

  @override
  State<YeolpumtaMainShell> createState() => _YeolpumtaMainShellState();
}

class _YeolpumtaMainShellState extends State<YeolpumtaMainShell> {
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AppServices.instance.authService;
  final VoiceLibraryRepository _repo = VoiceLibraryRepository();
  final UserProfileRepository _profileRepo =
      AppServices.instance.userProfileRepository;
  final PremiumRepository _premiumRepo = PremiumRepository();
  VoiceLibrarySnapshot _data = const VoiceLibrarySnapshot(
    folders: [],
    jobs: [],
  );
  UserProfile? _profile;
  bool _ready = false;
  bool _adsRemoved = false;
  bool _showInitialVoiceNativeAd = true;

  int _index = 0;
  bool _showTabCoach = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTabCoach());
  }

  Future<void> _syncTabCoach() async {
    if (!_ready || !mounted) return;
    final tab = _index.clamp(0, 1);
    if (tab == 0) {
      setState(() => _showTabCoach = false);
      return;
    }
    final dismissed = await OnboardingPrefs.isShellTabCoachDismissed(tab);
    if (!mounted) return;
    if (_index.clamp(0, 1) != tab) return;
    setState(() => _showTabCoach = !dismissed);
  }

  Future<void> _dismissTabCoach() async {
    final tab = _index.clamp(0, 1);
    await OnboardingPrefs.setShellTabCoachDismissed(tab);
    if (!mounted) return;
    setState(() => _showTabCoach = false);
  }

  Future<void> _refreshVoiceFolderScope([String? folderId]) async {
    final snap = await _repo.refreshFolderContents(_data, folderId: folderId);
    if (!mounted) return;
    setState(() => _data = snap);
  }

  Future<void> _reloadVoiceLibrary() async {
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() => _data = snap);
  }

  Future<String> _createFolderForUpload(
    String name,
    String? parentFolderId,
  ) async {
    final result = await _repo.createFolder(
      _data,
      name,
      parentFolderId: parentFolderId,
    );
    if (!mounted) throw StateError('unmounted');
    setState(() => _data = result.snapshot);
    await _refreshVoiceFolderScope(parentFolderId);
    return result.folderId;
  }

  Future<void> _submitVoiceUpload(VoiceUploadRequest upload) async {
    try {
      final next = await _repo.uploadVoice(_data, upload);
      if (!mounted) return;
      setState(() => _data = next);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성을 업로드했어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openUpload([String? initialFolderId]) async {
    final upload = await showModalBottomSheet<VoiceUploadRequest?>(
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
    if (upload == null || !mounted) return;
    await _submitVoiceUpload(upload);
  }

  Future<void> _openDirectRecord([String? initialFolderId]) async {
    final upload = await showModalBottomSheet<VoiceUploadRequest?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => VoiceRecordSheet(
        folders: _data.folders,
        initialFolderId: initialFolderId,
        onCreateFolder: _createFolderForUpload,
      ),
    );
    if (upload == null || !mounted) return;
    await _submitVoiceUpload(upload);
  }

  Future<void> _openFolderManage([String? currentFolderId]) async {
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
        currentFolderId: currentFolderId,
        onCreate: (name, parentFolderId) async {
          final result = await _repo.createFolder(
            _data,
            name,
            parentFolderId: parentFolderId,
          );
          if (!mounted) return;
          setState(() => _data = result.snapshot);
          await _refreshVoiceFolderScope(parentFolderId);
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
    try {
      final snap = await _repo.deleteJob(_data, id);
      if (!mounted) return;
      setState(() => _data = snap);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _moveJob(String jobId, String folderId) async {
    try {
      final snap = await _repo.moveJobToFolder(_data, jobId, folderId);
      if (!mounted) return;
      setState(() => _data = snap);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _renameJob(String jobId, String newName) async {
    try {
      final snap = await _repo.renameVoiceJob(_data, jobId, newName);
      if (!mounted) return;
      setState(() => _data = snap);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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

  Future<void> _goToLogin() async {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _goMyPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MyPage(
          isGuestMode: widget.isGuestMode,
          onRequireLogin: _goToLogin,
          repository: _repo,
          profileRepository: _profileRepo,
          folders: _data.folders,
          onCreateFolder: _createFolderForUpload,
          onAdvanceDemo: _advanceDemo,
          onDeleteJob: _deleteJob,
          onRenameJob: _renameJob,
          onMoveJob: _moveJob,
          onListenTap: _openListen,
          onAccountDeleted: () {
            _goToLogin();
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
        builder: (_) =>
            const PlaceholderPage(title: '설정', message: '알림·테마·계정·약관 (UI 데모)'),
      ),
    );
  }

  Future<void> _logout() async {
    if (!widget.isGuestMode) {
      await _authService.logout();
      if (!mounted) return;
    }
    await _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['음성', '함께'];

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
                      widget.isGuestMode
                          ? '게스트로 둘러보는 중 · 로그인 후 계정 기능 사용 가능'
                          : _profile == null
                          ? '로그인 유지 중'
                          : '${_profile!.nickname} · ${_profile!.email}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.92,
                        ),
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
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                      title: Text(
                        '고객센터',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: YeolpumtaTheme.textSecondary.withValues(
                            alpha: 0.95,
                          ),
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
                  widget.isGuestMode
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  color: widget.isGuestMode
                      ? YeolpumtaTheme.accent
                      : Colors.red.shade700,
                ),
                title: Text(
                  widget.isGuestMode ? '로그인 / 회원가입' : '로그아웃',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: widget.isGuestMode
                        ? YeolpumtaTheme.accent
                        : Colors.red.shade700,
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _index.clamp(0, 1),
                    children: [
                      if (!_adsRemoved && _showInitialVoiceNativeAd)
                        _InitialVoiceNativeAdGate(
                          onClose: () =>
                              setState(() => _showInitialVoiceNativeAd = false),
                        )
                      else
                        VoicePipelinePage(
                          jobs: _data.jobs,
                          folders: _data.folders,
                          onUploadTap: _openUpload,
                          onDirectRecordTap: _openDirectRecord,
                          onOpenFolderManage: _openFolderManage,
                          onCreateFolder: _createFolderForUpload,
                          onRefreshScope: _refreshVoiceFolderScope,
                          onAdvanceDemo: _advanceDemo,
                          onDeleteJob: _deleteJob,
                          onMoveJob: _moveJob,
                          onRenameJob: _renameJob,
                          onListenTap: _openListen,
                        ),
                      const RoomHubPage(embeddedInMainShell: true),
                    ],
                  ),
                ),
                if (_showTabCoach)
                  TabCoachOverlay(
                    tabIndex: _index.clamp(0, 1),
                    title: _tabCoachTitles[_index.clamp(0, 1)],
                    body: _tabCoachBodies[_index.clamp(0, 1)],
                    guestHint: widget.isGuestMode ? _kTabCoachGuestHint : null,
                    onGotIt: _dismissTabCoach,
                    onBarrierTap: () => setState(() => _showTabCoach = false),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_adsRemoved) const AppBannerAd(),
          NavigationBar(
            selectedIndex: _index.clamp(0, 1),
            onDestinationSelected: (i) async {
              final nextIndex = i.clamp(0, 1);
              setState(() {
                _index = nextIndex;
                _showTabCoach = false;
                if (nextIndex != 0) {
                  _showInitialVoiceNativeAd = false;
                }
              });
              if (nextIndex == 0) {
                await _reloadVoiceLibrary();
              }
              final v = await _premiumRepo.isAdsRemoved();
              if (mounted) setState(() => _adsRemoved = v);
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _syncTabCoach(),
                );
              }
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
            ],
          ),
        ],
      ),
    );
  }
}

class _InitialVoiceNativeAdGate extends StatefulWidget {
  const _InitialVoiceNativeAdGate({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_InitialVoiceNativeAdGate> createState() =>
      _InitialVoiceNativeAdGateState();
}

class _InitialVoiceNativeAdGateState extends State<_InitialVoiceNativeAdGate> {
  Timer? _fallbackTimer;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _adLoaded) return;
      widget.onClose();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _handleLoaded() {
    _adLoaded = true;
    _fallbackTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: YeolpumtaTheme.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Text(
              '음성 홈으로 들어가기 전에',
              style: TextStyle(
                color: YeolpumtaTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '짧은 추천 광고를 확인하면 바로 음성 탭을 사용할 수 있어요.',
              style: TextStyle(
                color: YeolpumtaTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppNativeAdCard(
              compact: true,
              spotlight: true,
              onClose: widget.onClose,
              onLoaded: _handleLoaded,
              onFailedToLoad: widget.onClose,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onClose,
              child: Text(
                '광고 닫고 음성 탭으로 이동',
                style: TextStyle(
                  color: YeolpumtaTheme.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
